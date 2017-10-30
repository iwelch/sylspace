#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::Index;
use Mojolicious::Lite;  ## implied strict, warnings, utf8, 5.10
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(isenrolled isinstructor);
use SylSpace::Model::Controller qw(global_redirect standard);

################################################################
## a redirector for instructors and students (not for auth!!)
################################################################

SylSpace::Model::Utils::_unsetsudo();

my $torealhome = sub {
  my $c = shift;

  (my $course = standard( $c )) or return global_redirect($c);

  ($course eq "auth") and return $c->redirect_to('/auth/index');

  my $curdomainport= $c->req->url->to_abs->domainport;

  (isenrolled( $course, $c->session->{uemail} ))
    or return $c->flash(message => 'who are you?  please authenticate')->redirect_to("http://auth.$curdomainport/index");

  ## _suundo();  ## sometimes after a direct redirect, this is oddly still set.  grrr

  my $desturl= isinstructor( $course, $c->session->{uemail} ) ? '/instructor' : '/student';

  return $c->flash(message => $c->session->{uemail}." logs into $course")->redirect_to($desturl)
};


get '/index' => $torealhome;
get '/' => $torealhome;

get '/exception.production' => sub { return render(template => 'exception.production'); };

1;

__DATA__

@@ exception.production.html.ep

%title 'please go back';
%layout 'auth';

  <main style="background-color:orange">
    <h1>Exception</h1>

      <p style="padding:2em;background-color:white"><%= $exception->message %></p>

  <p>Most of the time, the correct action is to go back to the URL that referred you here.</p>

  <p>If this error is an internal bug that you should not be seeing, then please describe how to reproduce it in an an email to <a href="mailto:ivo.welch@gmail.com">ivo welch</a>.  I will try to fix it.</p>

  <h2> Security? </h2>

  <p>The source code for SylSpace, running on this <%= $ENV{'SYLSPACE_sitename'} %> site, is public on <a href="https://github.com/iwelch/syllabus.space">github</a>, so it is not a security breach if you learn details about where the error has occurred (or a little more information why).</p>

  <p>However, if you notice a compromise of internal data that you should not have seen, or if you discover an exploitable security breach, please contact <a href="mailto:ivo.welch@gmail.com?subject=security breach on <%= $ENV{'SYLSPACE_sitename'} %>">ivo welch</a> urgently.</p>

  </main>

