#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::StudentFaq;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Files qw(filereads fileexistss);
use SylSpace::Model::Controller qw(global_redirect standard);

################################################################

get '/student/faq' => sub {
  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);

  my $isfaq= fileexistss($course, 'faq') ? filereads( $course, 'faq' ) : "<p>This instructor has not added a course-specific FAQ.</p>\n" ;

  use Perl6::Slurp;
  #TODO- NOENV - make sure this still works
  #my $body= slurp("$ENV{'SYLSPACE_sitepath'}/public/html/faq.html");
  my $body  = $c->home->child(qw/public html faq.html/);
  my $code= length($body) ? 404 : 200;

#  my $allfaq = $c->ua->get("/html/faq.html");
#  my $code= $allfaq->res->{code};
#  my $body= $allfaq->res->{content}->{asset}->{content};
#
#  if ($code == 404) {
#    $allfaq= "<p>There is no sitewide public /html/faq.html.</p>\n";
#  } else {
#    $body =~ s{.*(<body.*)}{$1}ms;
#    $body =~ s{(.*)</body>.*}{$1}ms;
#  }

## use Mojolicious::Plugin::ContentManagement::Type::Markdown;
## ($allfaq) or $allfaq = $markdown->translate(slurp("/faq.md"));

  $c->stash( allfaq => $body, isfaq => $isfaq, template => 'studentfaq' );
};

1;

################################################################

__DATA__

@@ studentfaq.html.ep

%title 'student faq';
%layout 'student';

<main>

<dl class="dl faq">

  <dt>What is <i>not</i> intuitive using SylSpace?  Have an idea to make it easier and better?  Found a dead link?</dt>

  <dd>Please <a href="mailto:ivo.welch@gmail.com?subject=unclear-SylSpace">let me know</a>.  I cannot guarantee that I will follow your recommendation(s), but I will consider it.</dd>

  <dt>Why won't my file upload?</dt>

  <dd>The maximum upload limit is 16MB/file.</dd>

</dl>

<hr />

<h1> Site FAQ </h1>

  <%== $allfaq %>

<hr />

<h3> Instructor-added Student FAQ </h3>

  <%== $isfaq %>

</main>

