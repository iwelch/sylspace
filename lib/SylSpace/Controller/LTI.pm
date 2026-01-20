#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

## LTI 1.1 integration for Canvas - allows equiz embedding in Canvas assignments

package SylSpace::Controller::LTI;
use Mojolicious::Lite;
use Mojo::JSON qw(decode_json encode_json);
use Mojo::UserAgent;
use Digest::SHA qw(hmac_sha1_base64);
use MIME::Base64 qw(encode_base64);
use URI::Escape qw(uri_escape);
use YAML::Tiny;

use SylSpace::Model::Model qw(equizrender equizgrade equizanswerrender superseclog);
use SylSpace::Model::Files qw(eqlisti);
use SylSpace::Model::Utils qw(_getvar _setsudo _unsetsudo);

my $vardir = _getvar();
my $lti_dir = "$vardir/lti";

################################################################
# LTI Configuration helpers
################################################################

sub _ensure_lti_dir {
  mkdir $lti_dir, 0700 unless -d $lti_dir;
  mkdir "$lti_dir/links", 0700 unless -d "$lti_dir/links";
}

sub _get_lti_config {
  _ensure_lti_dir();
  my $config_file = "$lti_dir/config.yml";
  return {} unless -e $config_file;
  return YAML::Tiny->read($config_file)->[0] // {};
}

sub _get_consumer_secret {
  my $consumer_key = shift;
  my $config = _get_lti_config();
  return $config->{consumers}{$consumer_key}{secret};
}

sub _get_link_mapping {
  my $resource_link_id = shift;
  _ensure_lti_dir();
  my $link_file = "$lti_dir/links/$resource_link_id.json";
  return undef unless -e $link_file;
  local $/;
  open my $fh, '<', $link_file or return undef;
  my $json = <$fh>;
  close $fh;
  return decode_json($json);
}

sub _save_link_mapping {
  my ($resource_link_id, $data) = @_;
  _ensure_lti_dir();
  my $link_file = "$lti_dir/links/$resource_link_id.json";
  open my $fh, '>', $link_file or die "Cannot write $link_file: $!";
  print $fh encode_json($data);
  close $fh;
}

################################################################
# OAuth 1.0 Signature Validation (for incoming LTI launches)
################################################################

sub _validate_oauth_signature {
  my $c = shift;
  
  my $consumer_key = $c->param('oauth_consumer_key');
  my $secret = _get_consumer_secret($consumer_key);
  return 0 unless $secret;
  
  # Build base string
  my $method = 'POST';
  my $url = $c->req->url->to_abs->to_string;
  $url =~ s/\?.*//;  # Remove query string
  
  # Collect all params except oauth_signature
  my %params;
  for my $name (@{$c->req->params->names}) {
    next if $name eq 'oauth_signature';
    $params{$name} = $c->param($name);
  }
  
  # Build parameter string (sorted, encoded)
  my $param_string = join('&', 
    map { uri_escape($_) . '=' . uri_escape($params{$_}) }
    sort keys %params
  );
  
  # Build base string
  my $base_string = join('&',
    $method,
    uri_escape($url),
    uri_escape($param_string)
  );
  
  # Calculate signature
  my $signing_key = uri_escape($secret) . '&';  # No token secret for LTI
  my $expected_sig = hmac_sha1_base64($base_string, $signing_key);
  $expected_sig .= '=' while length($expected_sig) % 4;  # Pad base64
  
  my $provided_sig = $c->param('oauth_signature');
  
  return $expected_sig eq $provided_sig;
}

################################################################
# OAuth 1.0 Signature Generation (for grade passback)
################################################################

sub _oauth_sign_request {
  my ($method, $url, $params, $consumer_key, $secret) = @_;
  
  my $oauth_params = {
    oauth_consumer_key => $consumer_key,
    oauth_signature_method => 'HMAC-SHA1',
    oauth_timestamp => time(),
    oauth_nonce => _random_string(32),
    oauth_version => '1.0',
  };
  
  # Merge params for signature
  my %all_params = (%$params, %$oauth_params);
  
  my $param_string = join('&',
    map { uri_escape($_) . '=' . uri_escape($all_params{$_}) }
    sort keys %all_params
  );
  
  my $base_string = join('&',
    $method,
    uri_escape($url),
    uri_escape($param_string)
  );
  
  my $signing_key = uri_escape($secret) . '&';
  my $signature = hmac_sha1_base64($base_string, $signing_key);
  $signature .= '=' while length($signature) % 4;
  
  $oauth_params->{oauth_signature} = $signature;
  return $oauth_params;
}

sub _random_string {
  my $len = shift // 32;
  my @chars = ('a'..'z', 'A'..'Z', '0'..'9');
  return join('', map { $chars[rand @chars] } 1..$len);
}

################################################################
# Grade Passback to Canvas
################################################################

sub _send_grade_to_canvas {
  my ($outcome_url, $sourcedid, $score, $max_score, $consumer_key, $secret) = @_;
  
  return 0 unless $outcome_url && $sourcedid;
  
  # Normalize score to 0.0 - 1.0
  my $normalized = ($max_score > 0) ? ($score / $max_score) : 0;
  $normalized = 0 if $normalized < 0;
  $normalized = 1 if $normalized > 1;
  
  my $message_id = time() . _random_string(8);
  
  my $xml = <<"XML";
<?xml version="1.0" encoding="UTF-8"?>
<imsx_POXEnvelopeRequest xmlns="http://www.imsglobal.org/services/ltiv1p1/xsd/imsoms_v1p0">
  <imsx_POXHeader>
    <imsx_POXRequestHeaderInfo>
      <imsx_version>V1.0</imsx_version>
      <imsx_messageIdentifier>$message_id</imsx_messageIdentifier>
    </imsx_POXRequestHeaderInfo>
  </imsx_POXHeader>
  <imsx_POXBody>
    <replaceResultRequest>
      <resultRecord>
        <sourcedGUID>
          <sourcedId>$sourcedid</sourcedId>
        </sourcedGUID>
        <result>
          <resultScore>
            <language>en</language>
            <textString>$normalized</textString>
          </resultScore>
        </result>
      </resultRecord>
    </replaceResultRequest>
  </imsx_POXBody>
</imsx_POXEnvelopeRequest>
XML

  # Sign the request
  my $oauth = _oauth_sign_request('POST', $outcome_url, {}, $consumer_key, $secret);
  
  my $auth_header = 'OAuth ' . join(', ',
    map { uri_escape($_) . '="' . uri_escape($oauth->{$_}) . '"' }
    sort keys %$oauth
  );
  
  my $ua = Mojo::UserAgent->new;
  my $tx = $ua->post($outcome_url => {
    'Authorization' => $auth_header,
    'Content-Type' => 'application/xml',
  } => $xml);
  
  return $tx->res->is_success;
}

################################################################
# LTI Launch Endpoint
################################################################

post '/lti/launch' => sub {
  my $c = shift;
  
  # Validate OAuth signature
  unless (_validate_oauth_signature($c)) {
    return $c->render(text => 'Invalid LTI signature', status => 401);
  }
  
  # Extract LTI parameters
  my $email = $c->param('lis_person_contact_email_primary');
  my $name = $c->param('lis_person_name_full') // $email;
  my $roles = $c->param('roles') // '';
  my $resource_link_id = $c->param('resource_link_id');
  my $context_id = $c->param('context_id');
  my $context_title = $c->param('context_title') // 'Canvas Course';
  my $consumer_key = $c->param('oauth_consumer_key');
  
  # Grade passback params (save for later)
  my $outcome_url = $c->param('lis_outcome_service_url');
  my $sourcedid = $c->param('lis_result_sourcedid');
  
  unless ($email && $resource_link_id) {
    return $c->render(text => 'Missing required LTI parameters', status => 400);
  }
  
  # Store LTI session data
  $c->session(
    lti_email => lc($email),
    lti_name => $name,
    lti_roles => $roles,
    lti_resource_link_id => $resource_link_id,
    lti_context_id => $context_id,
    lti_context_title => $context_title,
    lti_consumer_key => $consumer_key,
    lti_outcome_url => $outcome_url,
    lti_sourcedid => $sourcedid,
  );
  
  superseclog($c->tx->remote_address, $email, "LTI launch from Canvas context=$context_id");
  
  # Check if instructor or student
  my $is_instructor = ($roles =~ /Instructor|Administrator|ContentDeveloper/i);
  
  # Check if this resource_link has an equiz assigned
  my $mapping = _get_link_mapping($resource_link_id);
  
  if ($is_instructor) {
    # Instructor: show equiz selection or current assignment
    return $c->redirect_to('/lti/instructor/select');
  } else {
    # Student: show quiz if assigned, or "not yet available"
    if ($mapping && $mapping->{equiz}) {
      return $c->redirect_to('/lti/student/quiz');
    } else {
      return $c->render(
        template => 'lti_not_ready',
        format => 'html',
      );
    }
  }
};

################################################################
# Instructor: Select Equiz for Assignment
################################################################

get '/lti/instructor/select' => sub {
  my $c = shift;
  
  my $resource_link_id = $c->session('lti_resource_link_id');
  my $context_title = $c->session('lti_context_title');
  my $consumer_key = $c->session('lti_consumer_key');
  
  unless ($resource_link_id) {
    return $c->render(text => 'No LTI session - please launch from Canvas', status => 400);
  }
  
  # Get list of available equizzes from the LTI equiz repository
  my $equiz_dir = "$vardir/lti/equizzes";
  mkdir $equiz_dir, 0755 unless -d $equiz_dir;
  
  my @equizzes;
  opendir my $dh, $equiz_dir or die "Cannot open $equiz_dir: $!";
  while (my $f = readdir $dh) {
    next unless $f =~ /\.equiz$/;
    push @equizzes, $f;
  }
  closedir $dh;
  @equizzes = sort @equizzes;
  
  my $current = _get_link_mapping($resource_link_id);
  
  $c->stash(
    equizzes => \@equizzes,
    current_equiz => $current->{equiz} // '',
    context_title => $context_title,
  );
  
  $c->render(template => 'lti_instructor_select', format => 'html');
};

post '/lti/instructor/select' => sub {
  my $c = shift;
  
  my $resource_link_id = $c->session('lti_resource_link_id');
  my $context_id = $c->session('lti_context_id');
  my $email = $c->session('lti_email');
  
  unless ($resource_link_id) {
    return $c->render(text => 'No LTI session', status => 400);
  }
  
  my $equiz = $c->param('equiz');
  
  _save_link_mapping($resource_link_id, {
    equiz => $equiz,
    context_id => $context_id,
    set_by => $email,
    set_at => time(),
  });
  
  superseclog($c->tx->remote_address, $email, "LTI assigned equiz=$equiz to resource=$resource_link_id");
  
  $c->flash(message => "Equiz '$equiz' assigned to this Canvas assignment.");
  $c->redirect_to('/lti/instructor/select');
};

################################################################
# Student: Take Quiz
################################################################

get '/lti/student/quiz' => sub {
  my $c = shift;
  
  my $resource_link_id = $c->session('lti_resource_link_id');
  my $email = $c->session('lti_email');
  
  unless ($resource_link_id && $email) {
    return $c->render(text => 'No LTI session - please launch from Canvas', status => 400);
  }
  
  my $mapping = _get_link_mapping($resource_link_id);
  unless ($mapping && $mapping->{equiz}) {
    return $c->render(template => 'lti_not_ready', format => 'html');
  }
  
  my $equiz_file = "$vardir/lti/equizzes/$mapping->{equiz}";
  unless (-e $equiz_file) {
    return $c->render(text => "Equiz file not found: $mapping->{equiz}", status => 404);
  }
  
  # Render the equiz
  # We need to call the backend directly since we're not using the course structure
  my $callback_url = $c->url_for('/lti/student/submit')->to_abs->to_string;
  
  my $html = _render_lti_equiz($equiz_file, $email, $callback_url);
  
  $c->render(text => $html, format => 'html');
};

sub _render_lti_equiz {
  my ($equiz_file, $email, $callback_url) = @_;
  
  use Digest::MD5 qw(md5_base64);
  use Cwd qw(getcwd);
  
  my $secret = md5_base64((-e "/usr/local/var/lib/dbus/machine-id") 
    ? "/usr/local/var/lib/dbus/machine-id" 
    : "/etc/machine-id");
  
  my $executable = getcwd() . "/lib/SylSpace/Model/eqbackend/eqbackend.pl";
  
  # Fall back if running from different directory
  unless (-e $executable) {
    $executable = "$vardir/../SylSpace/lib/SylSpace/Model/eqbackend/eqbackend.pl";
  }
  unless (-e $executable) {
    $executable = "/home/sylspace/lib/SylSpace/Model/eqbackend/eqbackend.pl";
  }
  
  my @cmd = ($executable, $equiz_file, 'ask', $secret, $callback_url, $email);
  
  my $html;
  {
    local $SIG{CHLD} = 'DEFAULT';
    open(my $fh, '-|', @cmd) or die "Cannot execute equiz backend: $!";
    local $/;
    $html = <$fh>;
    close($fh);
  }
  
  return $html;
}

################################################################
# Student: Submit Quiz and Grade Passback
################################################################

post '/lti/student/submit' => sub {
  my $c = shift;
  
  my $resource_link_id = $c->session('lti_resource_link_id');
  my $email = $c->session('lti_email');
  my $outcome_url = $c->session('lti_outcome_url');
  my $sourcedid = $c->session('lti_sourcedid');
  my $consumer_key = $c->session('lti_consumer_key');
  
  unless ($resource_link_id && $email) {
    return $c->render(text => 'No LTI session', status => 400);
  }
  
  # Get all POST params as hash
  my %params;
  for my $name (@{$c->req->params->names}) {
    $params{$name} = $c->param($name);
  }
  
  # Grade the quiz using existing equizgrade logic
  my $result = _grade_lti_equiz(\%params, $email);
  
  my ($num_questions, $score, $uemail, $time, $gradename, $eqlongname, $fname, $confidential, $qlist) = @$result;
  
  superseclog($c->tx->remote_address, $email, "LTI equiz $gradename score=$score/$num_questions");
  
  # Send grade back to Canvas
  my $secret = _get_consumer_secret($consumer_key);
  my $passback_success = 0;
  
  if ($outcome_url && $sourcedid && $secret) {
    $passback_success = _send_grade_to_canvas(
      $outcome_url, $sourcedid, $score, $num_questions, $consumer_key, $secret
    );
    
    if ($passback_success) {
      superseclog($c->tx->remote_address, $email, "LTI grade passback success: $score/$num_questions");
    } else {
      $c->app->log->error("LTI grade passback failed for $email");
    }
  }
  
  # Render results
  my $results_html = _render_lti_results($result, $passback_success);
  $c->render(text => $results_html, format => 'html');
};

sub _grade_lti_equiz {
  my ($params, $email) = @_;
  
  use Crypt::CBC;
  use MIME::Base64;
  use HTML::Entities;
  use Digest::MD5 qw(md5_base64);
  use Scalar::Util qw(looks_like_number);
  
  my $secret = md5_base64((-e "/usr/local/var/lib/dbus/machine-id") 
    ? "/usr/local/var/lib/dbus/machine-id" 
    : "/etc/machine-id");
  
  my $cipherhandle = Crypt::CBC->new(-key => $secret, -cipher => 'Blowfish', -salt => '14151617');
  
  sub _decrypt {
    my ($cipherhandle, $val) = @_;
    my $step1 = decode_entities($val);
    my $step2 = decode_base64($step1);
    return $cipherhandle->decrypt($step2);
  }
  
  # Decrypt encrypted fields
  for my $key (keys %$params) {
    if ($key eq 'confidential' || $key =~ /^[ASPQN]-[0-9]+/) {
      $params->{$key} = _decrypt($cipherhandle, $params->{$key});
    }
  }
  
  my ($conf, $fname, undef, undef, $referrer, $qemail, $time, $browser, $ignoredgradename, $eqlongname) 
    = split(/\|/, $params->{confidential});
  
  ($conf eq 'confidential') or die "Invalid quiz submission";
  
  (my $gradename = $fname) =~ s{.*/}{};
  
  # Score the quiz
  my $i = 0;
  my $score = 0;
  my @qlist;
  
  while (++$i) {
    my $correct_answer = $params->{"S-$i"};
    last unless defined $correct_answer;
    
    looks_like_number($correct_answer) or die "Invalid correct answer for question $i";
    
    my $student_answer = $params->{"q-stdnt-$i"};
    defined($student_answer) or die "Missing student answer for question $i";
    looks_like_number($student_answer) or die "Invalid student answer for question $i";
    
    my $precision = $params->{"P-$i"} || 0.01;
    my $is_correct = (abs($student_answer - $correct_answer) < $precision);
    
    $score += $is_correct;
    
    push @qlist, [
      $params->{"N-$i"},      # question name
      $params->{"Q-$i"},      # question text
      $params->{"A-$i"},      # answer explanation
      $correct_answer,
      $student_answer,
      $precision,
      $is_correct ? "Correct" : "Incorrect",
    ];
  }
  --$i;
  
  return [$i, $score, $email, $time, $gradename, $eqlongname, $fname, $params->{confidential}, \@qlist];
}

sub _render_lti_results {
  my ($result, $passback_success) = @_;
  
  my ($num_q, $score, $email, $time, $gradename, $eqlongname, $fname, $conf, $qlist) = @$result;
  
  my $passback_msg = $passback_success 
    ? '<div class="alert alert-success">Grade sent to Canvas successfully!</div>'
    : '<div class="alert alert-warning">Note: Grade could not be sent to Canvas automatically.</div>';
  
  my $html = <<"HTML";
<!DOCTYPE html>
<html>
<head>
  <title>Quiz Results</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap\@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
  <script src="https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.1/MathJax.js?config=TeX-AMS_HTML-full"></script>
  <style>
    .correct { color: green; font-weight: bold; }
    .incorrect { color: red; font-weight: bold; }
    .question { border: 1px solid #ddd; padding: 15px; margin: 10px 0; border-radius: 5px; }
  </style>
</head>
<body>
<div class="container mt-4">
  <h2>Quiz Results: $eqlongname</h2>
  
  $passback_msg
  
  <div class="alert alert-info">
    <strong>Score: $score / $num_q</strong> 
    (@{[int(100 * $score / ($num_q || 1))]}%)
  </div>
  
  <h3>Question Details</h3>
HTML

  my $qnum = 0;
  for my $q (@$qlist) {
    $qnum++;
    my ($name, $text, $explanation, $correct, $student, $precision, $result_text) = @$q;
    my $class = ($result_text eq 'Correct') ? 'correct' : 'incorrect';
    
    $html .= <<"QHTML";
  <div class="question">
    <h5>Question $qnum: $name</h5>
    <p><strong>Question:</strong> $text</p>
    <p><strong>Your Answer:</strong> $student</p>
    <p><strong>Correct Answer:</strong> $correct (±$precision)</p>
    <p><strong>Explanation:</strong> $explanation</p>
    <p class="$class">$result_text</p>
  </div>
QHTML
  }

  $html .= <<"HTML";
  
  <div class="mt-4">
    <p>You may close this window and return to Canvas.</p>
  </div>
</div>
</body>
</html>
HTML

  return $html;
}

################################################################
# Templates
################################################################

1;

__DATA__

@@ lti_not_ready.html.ep
<!DOCTYPE html>
<html>
<head>
  <title>Quiz Not Available</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body>
<div class="container mt-5">
  <div class="alert alert-warning">
    <h4>Quiz Not Yet Available</h4>
    <p>The instructor has not yet assigned a quiz to this Canvas assignment.</p>
    <p>Please check back later or contact your instructor.</p>
  </div>
</div>
</body>
</html>

@@ lti_instructor_select.html.ep
<!DOCTYPE html>
<html>
<head>
  <title>Select Equiz - <%= $context_title %></title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body>
<div class="container mt-4">
  <h2>Assign Equiz to Canvas Assignment</h2>
  <p class="text-muted">Course: <%= $context_title %></p>
  
  <% if (my $msg = flash 'message') { %>
    <div class="alert alert-success"><%= $msg %></div>
  <% } %>
  
  <% if ($current_equiz) { %>
    <div class="alert alert-info">
      Currently assigned: <strong><%= $current_equiz %></strong>
    </div>
  <% } %>
  
  <form method="POST" action="/lti/instructor/select">
    <div class="mb-3">
      <label for="equiz" class="form-label">Select Equiz:</label>
      <select name="equiz" id="equiz" class="form-select" required>
        <option value="">-- Select an equiz --</option>
        <% for my $eq (@$equizzes) { %>
          <option value="<%= $eq %>" <%= $eq eq $current_equiz ? 'selected' : '' %>><%= $eq %></option>
        <% } %>
      </select>
    </div>
    <button type="submit" class="btn btn-primary">Assign Equiz</button>
  </form>
  
  <hr class="my-4">
  
  <h4>Available Equizzes</h4>
  <% if (@$equizzes) { %>
    <ul>
      <% for my $eq (@$equizzes) { %>
        <li><%= $eq %></li>
      <% } %>
    </ul>
  <% } else { %>
    <p class="text-muted">No equizzes found. Place .equiz files in /var/sylspace/lti/equizzes/</p>
  <% } %>
  
  <hr class="my-4">
  <p class="text-muted small">
    To add equizzes, place .equiz files in: <code>/var/sylspace/lti/equizzes/</code>
  </p>
</div>
</body>
</html>

