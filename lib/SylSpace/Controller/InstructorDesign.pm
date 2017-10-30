#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::InstructorDesign;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(sudo);
use SylSpace::Model::Controller qw(global_redirect  standard);

################################################################

get 'instructor/design' => sub {
  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);

  sudo( $course, $c->session->{uemail} );

  $c->stash( );
};

1;

################################################################

__DATA__

@@ instructordesign.html.ep

%title 'design an equiz question';
%layout 'instructor';

<main>

<h1>Not Yet</h1>

First, check the syntax of the equiz file, and then prefill fields

<h1>Sketch</h1>

<form method="POST" action="/instructor/designcollect">

<h2>Header Information</h2>

  <table class="table">

  <tr> <th> ::NAME:: </th> <td> <input name="NAME" placeholder="e.g., Black-Scholes Quiz" size="80" /> </td> </th>
  <tr> <th> ::INSTRUCTOR:: </th> <td> <input name="INSTRUCTOR" placeholder="e.g., Ivo Welch"  size="80" /> </td> </th>
  <tr> <th> ::AUTHOR:: </th> <td> <input name="AUTHOR" placeholder="e.g., RA1 "  size="80" /> </td> </th>
  <tr> <th> ::DATE:: </th> <td> <input name="DATE" placeholder="e.g., datepicker, 2014/12/31"  size="20" /> </td> </th>
  <tr> <th> ::GRADENAME:: </th> <td> <input name="GRADENAME" placeholder="e.g., equiz1 "  size="32" /> </td> </th>
  <tr> <th> ::AREA:: </th> <td> <input name="AREA" placeholder="e.g., Economics / Finance /Options "  size="80" /> </td> </th>
  <tr> <th> ::COMMENTS:: </th> <td> <input name="COMMENTS" placeholder="(ignored)"  size="80" /> </td> </th>

  </table>


<h2> Questions </h2>

<h3> Q1: Black Scholes Quiz </h3>

  <table class="table">

  <tr> <th> ::N:: </th> <td> <input name="N1" placeholder="e.g., Black-Scholes Quiz"  size="80"/> </td> </th>
  <tr> <th> ::I:: </th> <td> <input name="I1" placeholder="e.g., $x= rseq(10,20; $ANS= $x+1"  size="80"/> </td> </th>

  <tr> <th> ::Q:: </th> <td> <textarea name="Q1" cols="80" placeholder="e.g.,  This is the first question.  X=$x is a random integer number between 10 and 20.  Please calculate $x+1 and enter it as your answer. "></textarea> </td> </th>

  <tr> <th> ::A:: </th> <td> <textarea name="A1" cols="80" placeholder="e.g.,  When done, your students will be shown this long explanation, which can also use any of your variables.  So, here, the first correct answer adding 1 to $x should be $ANS. "></textarea> </td> </th>
  <tr> <th> ::T:: </th> <td> <input name="T1" placeholder="e.g., 10 " size="7" /> min </td> </th>

  <tr> <td colspan="2"> <button name="check" class="button btn" />Check Syntax</button>
  <button name="check" class="button btn" />Show Sample Evaluation</button>
    </td> </tr>
  </table>

<h3> Q2: ... </h3>

...


  <h2> Submit </h2>

  <button class="button btn btnlarge"> Save (Update) Quiz </button>

</form>

</main>

