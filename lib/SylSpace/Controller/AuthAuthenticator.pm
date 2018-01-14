#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::AuthAuthenticator;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

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

use Data::Dumper;

sub google {
  my ( $self, $access_token, $userinfo ) = @_;
  my $name = $userinfo->{displayName} || $userinfo->{name};
  my $email= $userinfo->{email};

  (defined($name)) or die "The google authentication failed finding a good name.  Here is what I got: ".Dumper($userinfo);
  (defined($email)) or die "The google authentication failed finding a good email.  Here is what I got: ".Dumper($userinfo);

  ## we could also pick off first and last name, but it ain't worth it
  ## my @emaillist = grep {$_->{type} eq 'account'} @{ $userinfo->{emails} };
  ## my $email= $emaillist[0]->{value};
  ## my $email = $userinfo->{emails}->[0]->{value};

  return logandreturn( $self, $email, $name, 'google' );
}

sub github {
  my ( $self, $access_token, $userinfo ) = @_;

  (defined($userinfo->{email})) or die "sadly, you have not confirmed your email with github, so you cannot use it to confirm it.\n";
  ($userinfo->{email} =~ /gmail.com$/) and die "sorry, but gmail accounts must be validated by google, not github";

  return logandreturn( $self, $userinfo->{email}, $userinfo->{name}, 'github' );
}

sub facebook {
  my ( $self, $access_token, $userinfo ) = @_;

  my $ua  = Mojo::UserAgent->new;
  my $res = $ua->get("https://graph.facebook.com/me?fields=name,email&access_token=$access_token")->result->json;

  if (!$res->{email}) {
    return $self->render(text => "Can't get your email from facebook, please try another auth method.");
  }
  ($res->{email} =~ /gmail.com$/) and die "sorry, but gmail accounts must be validated by google, not facebook";

  return logandreturn( $self, $res->{email}, $res->{name}, "facebook");
}

################################################################

get '/auth/authenticator' => sub {
  my $c = shift;

  (my $course = standard( $c )) or return global_redirect($c);

  $c->render(template => 'AuthAuthenticator' );
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
			body => '<p>It is safe to register and/or authenticate.  The site is run by Ivo Welch, Prof at UCLA.  For more information, please click on <a href="/aboutus">About Us</a>.   <p><b>Students</b>: Registration allows students to take sample tests, including a great set of corporate finance quizzes.  (A typical quiz looks like <a href="/html/eqsample02a.html">this rendering</a>.) <p><b>Instructors:</b> Instructors can also obtain an own tailored course site.  Course sites allow posting and changing equizzes, seeing what students have answered, distributing homeworks and collecting student answers.  The web interface is <em>far</em> simpler (no learning curve!) and more pleasing than anything else out there. See <a href="http://auth.syllabus.test/faq">screenshots</a>.  If interested, please <a href="mailto:ivo.welch@gmail.com">email to request</a> a tailored instructor site.  Include (1) a gmail address;  (2) a link to a university site so I can confirm your identity; and (3) a course name (such as mfe404) and year (such as 2018).  Your private website will be named something like <tt>http://<span style="color:blue">welch-mfe404-2018.ucla</span>.syllabus.space</tt>.<p>If you stumble upon little or not-so-little bugs, please let <a href="mailto:ivo.welch@gmail.com">me</a> know.'}] ) %>

<hr />

<nav>

  <% if ($ENV{SYLSPACE_haveoauth}) { %>

  <p style="font-size:small;"><b>Direct Authentication</b> is the fastest and most reliable method to authenticate.  It works with your google or facebook id.</p>

   <div class="row text-center">
     <%== btnblock('/auth/google/authenticate', '<i class="fa fa-google"></i> Google', 'Your Gmail ID') %>
    <!-- <%== btnblock('/auth/github/authenticate', '<i class="fa fa-github"></i> Github', 'Your Github ID<br />Disabled Until Approved', 'btn-disabled') %> -->
    <!-- <%== btnblock('/auth/facebook/authenticate', '<i class="fa fa-facebook"></i> Facebook', 'Your Facebook ID<br />Randomly Seems To Break Now.  Avoid.') %> -->
    <!-- <%== btnblock('/auth/ucla/authenticate', '<i class="fa fa-university"></i> UCLA', 'Your University ID<br />Disabled Until Approved', 'btn-disabled') %> -->
   </div>

  <p>Note that G Suite accounts (like <tt>g.ucla.edu</tt>) can also use our Google authentication.</p>

  <hr />

  <p style="font-size:small;padding-top:1em;">Alternatively, use sendmail.  It is slow, throttled per server (to avoid bot DDOS attacks on other servers), may take up to 10 minutes to arrive, and is only valid for 15 minutes&mdash;if you are lucky and no spam filter blocks it, in which case you will have to debug where your IT department or you have blocked the email.  If possible, avoid direct sendmail authentication.  Nevertheless, here it is: </p>

  <form name="registration" method="post" action="/auth/sendmail/authenticate">
       <input style="display:none" class="form-control" value="no name" name="name" />

    <div class="row text-center">

       <div class="col-md-5">
         <div class="input-group">
            <span class="input-group-addon">Email: <i class="fa fa-email"></i></span>
            <input class="form-control" placeholder="joe.schmoe@ucla.edu" name="outgemaildest" type="email" required />
         </div>
       </div>

       <div class="col-md-2">
          <div class="input-group">
             <button class="btn btn-default" type="submit" value="submit">Send Authorization Email</button>
          </div>
      </div>


  <% } else { %>

   <p style="font-size:small">You did not have a local OAuth config file (usually a link to SylSpace-Secrets.conf), so you cannot use direct or email based registration or authentication.  For now, you can only use this Syllabus webapp reasonably on http://syllabus.test (i.e., localhost), which only allows "local cheating" authentication.</p>

  <% } %>



     <% if ($ENV{'SYLSPACE_onlocalhost'}) { %>
        <div class="top-buffer text-center; border-style:solid;"> <!-- completely ignored afaik -->
           <%== btnblock('/auth/testsetuser', '<i class="fa fa-users"></i> Choose Existing Listed User', '(works only on localhost, usually syllabus.test)', 'btn-warning btn-md', 'w') %>
        </div>
      <% } %>

    </div> <!-- row -->

  </form>

<p style="font-size:x-small;padding-top:1ex"><a href="/auth/magic">magic</a> is only useful to the cli site admin</p>

</nav>

</main>
