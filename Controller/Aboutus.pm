#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::Aboutus;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(sudo);
use SylSpace::Model::Controller qw(global_redirect standard);

################################################################

get '/aboutus' => sub {
  my $c = shift;
  ## anyone is allowed to read this --- (my $course = standard( $c )) or return global_redirect($c);

  $c->stash( );
};

1;

################################################################

__DATA__

@@ aboutus.html.ep

%title 'about us';
%layout 'both';

<main>

<h2>Basics</h2>

  <p>SylSpace is free course administration and equizzing software, written in <a href="http://mojolicious.org/">Mojolicious</a> (perl) and <a href="http://getbootstrap.com">Bootstrap</a> (with <a href="http://fontawesome.io/">fontawesome icons</a>) in early 2017 by Ivo Welch (<a href="ivo.welch@gmail.com">ivo.welch@gmail.com</a>).  Special thanks to Sebastian Riedel for developing M and Stefan Adams for answering many questions on the M forum.</p>

<h2>Features and Screenshots</h2>

  <p>For basic information, please visit the <a href="/faq">FAQ</a>.</p>

<h2>License</h2>

  <p>The SylSpace software is free under dual licenses: first, an <a href="https://choosealicense.com/licenses/agpl-3.0/">GNU AGPLv3</a> license.  AGPL is a stringent open-source license, requiring making all modifications and changes available to others.  Alternatively, SylSpace is also available for sale under a non-exclusive commercial license for $100,000/year, which allows proprietary modification that are permitted not to have to flow back into the GPL.</p>

<h2>Legal</h2>

  <p>NO REPRESENTATIONS OR WARRANTIES, EITHER EXPRESS OR IMPLIED, OF MERCHANTABILITY, FITNESS FOR A SPECIFIC PURPOSE, THE PRODUCTS TO WHICH THE INFORMATION MENTIONS MAY BE USED WITHOUT INFRINGING THE INTELLECTUAL PROPERTY RIGHTS OF OTHERS, OR OF ANY OTHER NATURE ARE MADE WITH RESPECT TO INFORMATION OR THE PRODUCT TO WHICH INFORMATION MENTIONS. IN NO CASE SHALL THE INFORMATION BE CONSIDERED A PART OF OUR TERMS AND CONDITIONS OF SALE.</p>


<h2>Breach</h2>

  <p>You accept the risk that all information on this website may get compromised by hacker.  Breakins are a fact of life on the modern web.  We try our best to prevent it, but there is no absolute certainty here.</p>

</main>

