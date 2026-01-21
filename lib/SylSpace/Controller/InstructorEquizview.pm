#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::InstructorEquizview;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(sudo equizpreview);
use SylSpace::Model::Controller qw(global_redirect standard);

################################################################

get '/instructor/equizview' => sub {
  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);

  sudo( $course, $c->session->{uemail} );

  my $fname = $c->req->query_params->param('f');
  (defined($fname)) or return $c->flash(message => "need a filename")->redirect_to($c->req->headers->referrer);

  my $preview = equizpreview($course, $fname);

  $c->stash(
    content => $preview,
    quizname => $fname,
  );
};

1;

################################################################

__DATA__

@@ instructorequizview.html.ep

%title 'preview equiz';
%layout 'instructor';

    <script type="text/javascript" async src="https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.1/MathJax.js?config=TeX-MML-AM-CHTML"></script>
    <script type="text/javascript"       src="https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.1/MathJax.js?config=TeX-AMS_HTML-full"></script>

  <script type="text/javascript" src="/js/eqbackend.js"></script>
  <link href="/css/eqbackend.css" media="screen" rel="stylesheet" type="text/css" />
  <link href="/css/input.css" media="screen" rel="stylesheet" type="text/css" />

  <script type="text/x-mathjax-config">
  MathJax.Hub.Register.StartupHook("TeX Jax Ready",function () {
    MathJax.InputJax.TeX.Definitions.number =
      /^(?:[0-9]+(?:,[0-9]{3})*(?:\.[0-9]*)*|\.[0-9]+)/
    });
  </script>

<main>

<div class="alert alert-info" style="font-size:1.2em; text-align:center;">
  <strong>Preview Mode:</strong> Viewing equiz as if student had entered "0" as answer to every question
</div>

<h2>Quiz Preview: <%= $quizname %></h2>

<%== $content %>

</main>

