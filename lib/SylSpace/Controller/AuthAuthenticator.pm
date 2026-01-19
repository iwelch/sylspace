##!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::AuthAuthenticator;
use Mojolicious::Lite;
use Mojo::Promise;
use Mojo::URL;

use SylSpace::Model::Model qw(superseclog);
use SylSpace::Model::Controller qw(global_redirect standard);

sub logandreturn {
  my ( $self, $email, $name, $authenticator ) = @_;
  (defined($email)) or $email="no-email-in-log-and-return";
  (defined($name)) or $name="no-name-in-log-and-return";

  superseclog($self->tx->remote_address, $email, "logging in $email ($name) via $authenticator" );
  $self->session(uemail => $email, name => $name, expiration => time()+60*60); ## one hour default
  return $self->redirect_to('/index');
}

get '/auth/authenticator' => sub {
  my $c = shift;

  (my $course = standard( $c )) or return global_redirect($c);
  
  my @providers = keys %{$c->config->{oauth}};
  
  $c->stash(
    providers => [
      map {{ 
        title => ucfirst($_),
        name => $_,
        url  => $c->oauth2->auth_url($_,
          { redirect_uri => $c->auth_path("/auth/login/$_") }
        ) 
      }} reverse sort @providers
    ]
  );
  $c->render(template => 'AuthAuthenticator' );
};


get "/auth/login/:provider" => [ provider => [ 'google', 'github', 'facebook' ] ] => sub {
  my $c = shift;
  my $provider = $c->stash('provider');

  my $data = $c->oauth2->get_token($provider);

  my $token = $data->{access_token};
 	
  my ($email, $name);
  my @promises;
  my %get_info = (
    google => sub { 
      my $target = Mojo::URL->new(
        'https://www.googleapis.com/oauth2/v2/userinfo');
      $target->query(access_token => $token);
      push @promises, $c->ua
      ->get_p($target)
      ->then(sub {
        my $tx = shift;
        my $res = $tx->result->json;
        $email = $res->{email};
        $name = $res->{name} || $res->{given_name}." ".$res->{family_name};
      })
    },
    github => sub {
      my $header = { Authorization => "token $token" };
      push @promises, $c->ua
        ->get_p('https://api.github.com/user', $header )
        ->then(sub {
          my $tx = shift;
          $name = $tx->result->json->{name};
        });
      push @promises, $c->ua
        ->get_p('https://api.github.com/user/emails', $header)
        ->then(sub {
          my $tx = shift;
          my @emails = @{ $tx->result->json };
          ($email) = map $_->{email}, grep $_->{primary}, @emails
        });
    },
    facebook => sub {
      my $target = Mojo::URL->new('https://graph.facebook.com/v7.0/me');
      $target->query(access_token => $token, fields => 'name,email');
      push @promises, $c->ua
        ->get_p($target)
        ->then( sub {
          my $tx = shift;
          my $res = $tx->result->json;
          $name = $res->{name};
          $email = $res->{email};
        })
    }
  );
  $get_info{$provider}->();
  $c->render_later;
  Mojo::Promise->all(@promises)
    ->then( sub { logandreturn($c, $email, $name, $provider) })
};

1;

################################################################

__DATA__

@@ AuthAuthenticator.html.ep

%title 'register or authenticate';
%layout 'auth';

<% use SylSpace::Model::Controller qw(btnblock msghash2string); %>

<main>

<p style="margin:1em"> To learn more about this site, please visit the <a href="/aboutus">about us</a> page.</p>

  <%== msghash2string( [{ msgid => 0, priority => 5, time => 1495672668, subject => 'Hello!',
			body => <<"MSGBODY" }] ) 
<p>It is safe to register and/or authenticate.  The site is run by Ivo
Welch, Prof at UCLA.  For more information, please click on <a
href="/aboutus">About Us</a>.  

<p><b>Students</b>: Registration allows students to take sample tests, including a
great set of corporate finance quizzes.  (A typical quiz looks like <a
href="/html/eqsample02a.html">this rendering</a>.)
                       
<p><b>Instructors:</b> Instructors can also obtain an own tailored course site.  Course sites allow
posting and changing equizzes, seeing what students have answered, distributing
homeworks and collecting student answers.  The web interface is <em>far</em> simpler
(no learning curve!) and more pleasing than anything else out there.
See ${\link_to screenshots => 'faq'}

If interested, please <a href="mailto:ivo.welch\@gmail.com">email to
request</a> a tailored instructor site.  Include (1) a gmail address;  (2) a link
to a university site so I can confirm your identity; and (3) a course name (such as
mfe404) and year (such as 2018).  Your private website will be named something
like <tt>http://<span style="color:blue">welch-mfe404-2018.ucla</span>.${\sitename}</tt>.<p>If
you stumble upon little or not-so-little bugs, please let <a href="mailto:ivo.welch\@gmail.com">me</a> know.
</p>
MSGBODY
    %>

<hr />

<nav>

  <% if (has_oauth) { %>


  <p style="font-size:small;"><b>Direct Authentication</b> is the fastest and most reliable method to authenticate.  It works with your google or facebook id.</p>

   <div class="row text-center">
     % for my $oauth (@$providers) {
       <%== btnblock $oauth->{url},
            qq'<i class="fa fa-$oauth->{name}"></i> $oauth->{title}',
            "Your $oauth->{title} ID"
          %>
     % }
   </div>

  <p>Note that G Suite accounts (like <tt>g.ucla.edu</tt>) can also use our Google authentication.</p>

  <% } else { %>

   <p style="font-size:small">You did not have a local OAuth config file (usually a link to SylSpace-Secrets.conf), so you cannot use direct registration or authentication.  For now, you can only use this Syllabus webapp reasonably on lvh.me (i.e., localhost), which only allows "local cheating" authentication.</p>

  <% } %>



     <% if (app->mode eq 'development') { %>
        <div class="top-buffer text-center; border-style:solid;"> <!-- completely ignored afaik -->
           <%== btnblock('/auth/testsetuser', '<i class="fa fa-users"></i> Choose Existing Listed User', '(works only on localhost, usually lvh.me)', 'btn-warning btn-md', 'w') %>
        </div>
      <% } %>

<p style="font-size:x-small;padding-top:1ex"><a href="/auth/magic">magic</a> is only useful to the cli site admin</p>

</nav>

</main>
