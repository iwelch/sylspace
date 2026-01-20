#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::AuthPasskey;
use Mojolicious::Lite;
use Mojo::JSON qw(decode_json encode_json);
use MIME::Base64 qw(encode_base64 decode_base64);

use SylSpace::Model::Model qw(superseclog);
use SylSpace::Model::Controller qw(global_redirect standard);
use SylSpace::Model::Utils qw(_getvar);

use Authen::WebAuthn;

my $vardir = _getvar();
my $passkey_dir = "$vardir/passkeys";

# Ensure passkey storage directory exists
# URL-safe base64 encoding/decoding (more portable than MIME::Base64::encode_base64url)
# Simple hex encoding for binary data (more reliable than base64)
sub _hex_encode {
  my $data = shift;
  return unpack('H*', $data);
}

sub _hex_decode {
  my $hex = shift;
  return pack('H*', $hex);
}

# Keep base64url for challenges (browser expects this format)
sub _b64url_encode {
  my $data = shift;
  my $b64 = encode_base64($data, '');
  $b64 =~ tr|+/=|-_|d;
  return $b64;
}


sub _ensure_passkey_dir {
  unless (-d $passkey_dir) {
    mkdir $passkey_dir, 0700 or die "Cannot create $passkey_dir: $!";
  }
}

# Get relying party ID from config
sub _get_rp_id {
  my $c = shift;
  my $site = $c->config->{site_name} // 'lvh.me';
  # RP ID should be the domain without port
  $site =~ s/:.*//;
  return $site;
}

# Get origin URL
sub _get_origin {
  my $c = shift;
  # Use actual request URL to handle subdomains like auth.syllabus.space
  my $url = $c->req->url->to_abs;
  my $origin = $url->scheme . "://" . $url->host;
  $origin .= ":" . $url->port if $url->port && $url->port != 80 && $url->port != 443;
  return $origin;
}

# Store passkey credential for user
sub _store_credential {
  my ($email, $credential_id, $public_key, $name) = @_;
  _ensure_passkey_dir();
  
  my $user_file = "$passkey_dir/" . _email_to_filename($email);
  my $creds = [];
  
  if (-e $user_file) {
    local $/;
    open my $fh, '<', $user_file or die "Cannot read $user_file: $!";
    my $json = <$fh>;
    close $fh;
    $creds = decode_json($json) if $json;
  }
  
  push @$creds, {
    credential_id => $credential_id,
    public_key => $public_key,
    name => $name,
    created => time(),
  };
  
  open my $fh, '>', $user_file or die "Cannot write $user_file: $!";
  print $fh encode_json($creds);
  close $fh;
}

# Get stored credentials for user
sub _get_credentials {
  my ($email) = @_;
  _ensure_passkey_dir();
  
  my $user_file = "$passkey_dir/" . _email_to_filename($email);
  return [] unless -e $user_file;
  
  local $/;
  open my $fh, '<', $user_file or return [];
  my $json = <$fh>;
  close $fh;
  return decode_json($json) // [];
}

# Find user by credential ID
sub _find_user_by_credential {
  my ($credential_id) = @_;
  _ensure_passkey_dir();
  
  opendir my $dh, $passkey_dir or return (undef, undef);
  while (my $file = readdir $dh) {
    next if $file =~ /^\./;
    my $path = "$passkey_dir/$file";
    next unless -f $path;
    
    local $/;
    open my $fh, '<', $path or next;
    my $json = <$fh>;
    close $fh;
    
    my $creds = decode_json($json) // [];
    for my $cred (@$creds) {
      if ($cred->{credential_id} eq $credential_id) {
        my $email = _filename_to_email($file);
        closedir $dh;
        return ($email, $cred);
      }
    }
  }
  closedir $dh;
  return (undef, undef);
}

# Convert email to safe filename
sub _email_to_filename {
  my $email = shift;
  $email =~ s/[^a-zA-Z0-9@._-]/_/g;
  return $email . '.json';
}

# Convert filename back to email
sub _filename_to_email {
  my $file = shift;
  $file =~ s/\.json$//;
  return $file;
}

# Generate random bytes as base64url
sub _random_base64url {
  my $len = shift // 32;
  my $bytes = '';
  for (1..$len) {
    $bytes .= chr(int(rand(256)));
  }
  return _b64url_encode($bytes);
}

################################################################
# Registration: Step 1 - Get challenge and options
################################################################

post '/auth/passkey/register/begin' => sub {
  my $c = shift;
  
  # SECURITY: Only allow registration for already-authenticated users
  my $email = $c->session('uemail');
  unless ($email) {
    return $c->render(json => { error => 'You must be logged in to register a passkey' }, status => 401);
  }
  my $name = $c->session('name') // $email;
  
  my $rp_id = _get_rp_id($c);
  my $challenge = _random_base64url(32);
  
  # Store challenge in session for verification
  $c->session(passkey_challenge => $challenge);
  $c->session(passkey_email => $email);
  $c->session(passkey_name => $name);
  
  # Create user ID (hash of email)
  my $user_id = _b64url_encode($email);
  
  # Get existing credentials to exclude
  my $existing = _get_credentials($email);
  my @exclude = map { { type => 'public-key', id => $_->{credential_id} } } @$existing;
  
  my $options = {
    publicKey => {
      challenge => $challenge,
      rp => {
        name => 'SylSpace',
        id => $rp_id,
      },
      user => {
        id => $user_id,
        name => $email,
        displayName => $name,
      },
      pubKeyCredParams => [
        { type => 'public-key', alg => -7 },   # ES256
        { type => 'public-key', alg => -257 }, # RS256
      ],
      timeout => 60000,
      attestation => 'none',
      authenticatorSelection => {
        authenticatorAttachment => 'platform',
        residentKey => 'preferred',
        userVerification => 'preferred',
      },
      excludeCredentials => \@exclude,
    }
  };
  
  $c->render(json => $options);
};

################################################################
# Registration: Step 2 - Verify and store credential
################################################################

post '/auth/passkey/register/finish' => sub {
  my $c = shift;
  
  my $challenge = $c->session('passkey_challenge');
  my $email = $c->session('passkey_email');
  my $name = $c->session('passkey_name');
  
  unless ($challenge && $email) {
    return $c->render(json => { error => 'Session expired, please try again' }, status => 400);
  }
  
  my $credential = $c->req->json;
  unless ($credential && $credential->{id}) {
    return $c->render(json => { error => 'Invalid credential data' }, status => 400);
  }
  
  my $rp_id = _get_rp_id($c);
  my $origin = _get_origin($c);
  
  eval {
    my $webauthn = Authen::WebAuthn->new(
      rp_id => $rp_id,
      origin => $origin,
    );
    
    my $result = $webauthn->validate_registration(
      challenge_b64 => $challenge,
      client_data_json_b64 => $credential->{response}{clientDataJSON},
      attestation_object_b64 => $credential->{response}{attestationObject},
      requested_uv => 'preferred',
    );
    
    # Store the credential - credential_pubkey as-is from Authen::WebAuthn
    _store_credential(
      $email,
      $credential->{id},
      $result->{credential_pubkey},
      $name
    );
    
    # Clear session
    delete $c->session->{passkey_challenge};
    delete $c->session->{passkey_email};
    delete $c->session->{passkey_name};
    
    superseclog($c->tx->remote_address, $email, "registered passkey for $email");
    
    $c->render(json => { success => 1, message => 'Passkey registered successfully' });
  };
  if ($@) {
    $c->app->log->error("Passkey registration failed: $@");
    $c->render(json => { error => "Registration failed: $@" }, status => 400);
  }
};

################################################################
# Authentication: Step 1 - Get challenge
################################################################

post '/auth/passkey/login/begin' => sub {
  my $c = shift;
  
  my $rp_id = _get_rp_id($c);
  my $challenge = _random_base64url(32);
  
  $c->session(passkey_auth_challenge => $challenge);
  
  # For discoverable credentials, we don't need to specify allowCredentials
  my $options = {
    publicKey => {
      challenge => $challenge,
      rpId => $rp_id,
      timeout => 60000,
      userVerification => 'preferred',
    }
  };
  
  $c->render(json => $options);
};

################################################################
# Authentication: Step 2 - Verify assertion
################################################################

post '/auth/passkey/login/finish' => sub {
  my $c = shift;
  
  my $challenge = $c->session('passkey_auth_challenge');
  unless ($challenge) {
    return $c->render(json => { error => 'Session expired, please try again' }, status => 400);
  }
  
  my $assertion = $c->req->json;
  unless ($assertion && $assertion->{id}) {
    return $c->render(json => { error => 'Invalid assertion data' }, status => 400);
  }
  
  my $credential_id = $assertion->{id};
  my ($email, $stored_cred) = _find_user_by_credential($credential_id);
  
  unless ($email && $stored_cred) {
    return $c->render(json => { error => 'Unknown credential' }, status => 400);
  }
  
  my $rp_id = _get_rp_id($c);
  my $origin = _get_origin($c);
  
  eval {
    my $webauthn = Authen::WebAuthn->new(
      rp_id => $rp_id,
      origin => $origin,
    );
    
    $webauthn->validate_assertion(
      challenge_b64 => $challenge,
      credential_pubkey => $stored_cred->{public_key},
      stored_sign_count => $stored_cred->{sign_count} // 0,
      client_data_json_b64 => $assertion->{response}{clientDataJSON},
      authenticator_data_b64 => $assertion->{response}{authenticatorData},
      signature_b64 => $assertion->{response}{signature},
      requested_uv => 'preferred',
    );
    
    # Clear challenge
    delete $c->session->{passkey_auth_challenge};
    
    # Log in the user
    my $name = $stored_cred->{name} // $email;
    superseclog($c->tx->remote_address, $email, "logged in $email via passkey");
    $c->session(uemail => $email, name => $name, expiration => time()+60*60);
    
    $c->render(json => { success => 1, redirect => '/index' });
  };
  if ($@) {
    $c->app->log->error("Passkey authentication failed: $@");
    $c->render(json => { error => "Authentication failed: $@" }, status => 400);
  }
};

################################################################
# Passkey registration/login page
################################################################

get '/auth/passkey' => sub {
  my $c = shift;
  (my $course = standard($c)) or return global_redirect($c);
  $c->render(template => 'AuthPasskey');
};

1;

################################################################

__DATA__

@@ AuthPasskey.html.ep

%title 'Sign in with Passkey';
%layout 'auth';

<main>

<h2>Sign in with Passkey</h2>

<p>Passkeys let you sign in securely using Face ID, Touch ID, Windows Hello, or a security key — no password needed.</p>

<div id="passkey-status" class="alert" style="display:none;"></div>

<hr />

<p>If you've already registered a passkey, click below to sign in:</p>
<button id="passkey-login-btn" class="btn btn-primary btn-lg">
  <i class="fa fa-key"></i> Sign in with Passkey
</button>

<hr />

<p style="font-size:small;"><b>Don't have a passkey yet?</b> First sign in with Google, GitHub, or Facebook, then go to your <a href="/auth/bioform">profile settings</a> to register a passkey for future logins.</p>

<p><a href="/auth/authenticator">&larr; Back to other sign-in options</a></p>

</main>

<script>
function base64urlToBuffer(base64url) {
  const base64 = base64url.replace(/-/g, '+').replace(/_/g, '/');
  const pad = base64.length % 4;
  const padded = pad ? base64 + '='.repeat(4 - pad) : base64;
  const binary = atob(padded);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes.buffer;
}

function bufferToBase64url(buffer) {
  const bytes = new Uint8Array(buffer);
  let binary = '';
  for (let i = 0; i < bytes.length; i++) {
    binary += String.fromCharCode(bytes[i]);
  }
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

function showStatus(msg, isError) {
  const el = document.getElementById('passkey-status');
  el.textContent = msg;
  el.className = 'alert ' + (isError ? 'alert-danger' : 'alert-success');
  el.style.display = 'block';
}

if (!window.PublicKeyCredential) {
  showStatus('Passkeys are not supported in this browser. Please use a modern browser.', true);
  document.getElementById('passkey-login-btn').disabled = true;
}

document.getElementById('passkey-login-btn').addEventListener('click', async function() {
  try {
    const optionsRes = await fetch('/auth/passkey/login/begin', {
      method: 'POST'
    });
    const options = await optionsRes.json();
    
    if (options.error) {
      showStatus(options.error, true);
      return;
    }
    
    options.publicKey.challenge = base64urlToBuffer(options.publicKey.challenge);
    
    const assertion = await navigator.credentials.get(options);
    
    const finishRes = await fetch('/auth/passkey/login/finish', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        id: assertion.id,
        rawId: bufferToBase64url(assertion.rawId),
        type: assertion.type,
        response: {
          clientDataJSON: bufferToBase64url(assertion.response.clientDataJSON),
          authenticatorData: bufferToBase64url(assertion.response.authenticatorData),
          signature: bufferToBase64url(assertion.response.signature),
          userHandle: assertion.response.userHandle ? bufferToBase64url(assertion.response.userHandle) : null
        }
      })
    });
    const result = await finishRes.json();
    
    if (result.success) {
      showStatus('Success! Redirecting...', false);
      window.location.href = result.redirect || '/index';
    } else {
      showStatus(result.error || 'Login failed', true);
    }
  } catch (err) {
    console.error(err);
    if (err.name === 'NotAllowedError') {
      showStatus('Authentication was cancelled or timed out.', true);
    } else {
      showStatus('Error: ' + err.message, true);
    }
  }
});
</script>
