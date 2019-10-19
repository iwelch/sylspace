#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package EvalOneQuestion;
use strict;
use warnings;
use warnings FATAL => qw{ uninitialized };

use Safe;
use Data::Dumper;
use Math::Round; # qw(:all);  ## may not be used

################################################################################################################################

=pod

=head1 NAME

   EvalOneQuestion.pm --- given the variables, generate a specific instance of the question.

=head1 Input Example

   {
    'I' => '$ANS=undef ;  $x= rseq(10,20); $ANS= $x+1',
    'Q' => ' X={$x} is a random integer number between 10 and 20.  Please calculate {$x}+1 and enter it as your answer.',
    'A' => ' When done, students see long explanation, which can also use vars.  So, here, the correct answer should be {$ANS}.',

    ... anything else, such as ...
    'N' => ' A simple algorithmic question ',
    'T' => ' 1',
    'Q_' => ' This is the not processed.  usually copy of question.',
    'CNT' => 1,
    'S_' => ' $ANS',
   };


=head1 Output Example

   {
    'Q' => ' X=17 is a random integer number between 10 and 20.  Please calculate 17+1 and enter it as your answer.',
    'A' => ' When done, students see long explanation, which can also use vars.  So, here, the correct answer should be 18.',

    ... and everything else untouched, such as ...
    'I' => '$ANS=undef ;  $x= rseq(10,20); $ANS= $x+1',
    'N' => ' A simple algorithmic question ',
    'T' => ' 1',
    'Q_' => ' This is the not processed.  usually copy of question.',
    'CNT' => 1,
    'S_' => ' $ANS',
   };

  to help the writer of questions, we try to add some syntax checking.

=head1 Warning

  we do not have great debugging support.  so if you have parse
  problems, try to whittle down the template to the smallest example

=cut

## one time
my $predefinedfunctions = do { local $/=undef; <EvalOneQuestion::DATA> };
($predefinedfunctions) or die "perl $0: ERROR: data problem!\n";

################################################################

sub evaloneqstn {

  (defined($_[0])) or die "perl $0: ERROR: evaloneqstn is lucid.\n";

  my %qstn = %{$_[0]};
  my $linenum= $_[1] || "'$qstn{'N'}'" || "unknown";

  (defined($qstn{'N'})) or die "perl $0: ERROR: you have a qstn without a name: ".Dumper($_[0]);
  (($qstn{'N'})) or die "perl $0: ERROR: you have a qstn without a meaningful name".Dumper($_[0]);


  foreach my $danger (qw/use exec system eval open env path/) {
    ($qstn{'I'} =~ /\b$danger\b/i) and die "perl $0: ERROR: Keyword '$danger' is not allowed in equiz init.\n";
  }
  ($qstn{'I'} =~ /\#\@/) and die "perl $0: ERROR: no hash or at key allowed.\n";
  ($qstn{'I'} =~ /[\"\`\']/) and die "perl $0: ERROR: no strings and backquotes allowed.\n";


  ## First, we need to calculate all our variables in the init (:I:)
  my $compartment = new Safe;
  {
    $compartment->permit(qw/ :base_math  /);

    ## change some of perl math into better and more intuitive math
    $qstn{'I'} =~ s/\^/**/g; ##  perl does not think '^' is exponentiation; we do.

    ## allow syntax to define a function like 'function sqr($x) { return ($x*$x); }'
    $qstn{'I'} =~ s/function\s+([a-zA-Z0-9\_]+)\(\s*\$([a-zA-Z0-9\_]+)\s*\)\s*\{/sub $1 \{ my (\$$2)=\@_ ;/g;
    ## same for more arguments
    $qstn{'I'} =~ s/function\s+([a-zA-Z0-9\_]+)\(\s*\$([a-zA-Z0-9\_]+)\s*\,\s*\$([a-zA-Z0-9\_]+)\s*\)\s*\{/sub $1 \{ my (\$$2,\$$3)=\@_ ;/g;
    $qstn{'I'} =~ s/function\s+([a-zA-Z0-9\_]+)\(\s*\$([a-zA-Z0-9\_]+)\s*\,\s*\$([a-zA-Z0-9\_]+)\,\s*\$([a-zA-Z0-9\_]+)\s*\)\s*\{/sub $1 \{ my (\$$2,\$$3,\$$4)=\@_ ;/g;

    use Data::Dumper;
    local $SIG{__WARN__} = sub { die "perl $0: ERROR: ".$_[0]; };
    $compartment->reval("$predefinedfunctions ; $qstn{'I'}");
    ($@ eq "")
      or die "perl $0: ERROR: Your init :I: evaluation algebraic expression string '<tt>$qstn{'I'}</tt>' for $qstn{'N'} ending on line $linenum failed with $@.  Please fix and try again.\n\n<pre>".Dumper(\%qstn)."</pre>";
  }

  ## collect all variables that appeared in the init
  my %variables;
  while ($qstn{'I'} =~ /\$([a-zA-Z\_][\w]*)/g) {
    (exists($variables{$1})) and next;
    $variables{$1}= ${$compartment->varglob($1)};  ## with value
  }

  $qstn{'S'} = $variables{'ANS'};
  (defined($qstn{'S'})) or die "perl $0: ERROR: You must define an '\$ANS' variable in your :I: init segment for $qstn{'N'}\n";
  $qstn{'S'} = nearest(0.0000001, $qstn{'S'});

  # now we fill calculated variables into the question (:Q:) and answer (:A:)
  # longest first, so $x1 and $x1d will resolve in favor of $x1, but we still allow $x1e
  foreach my $vn (sort { length $b <=> length $a } keys %variables) {
    (defined($qstn{'Q'})) or die "perl $0: ERROR: Question $qstn{'N'} has no :Q: (question) key\n";

    sub replonevar {
      my ($qtext, $vnm, $val)= @_;
      use Scalar::Util qw(looks_like_number);
      (looks_like_number($val)) or return $qtext;
      ## or die "perl $.: ERROR: Sorry, but the input to replonevar of '$val' is not a number.\n";
      ## my $posval= abs($val);
      $qtext =~ s/\{\$$vnm:([0-9])\}/sprintf("%.${1}f",$val)/ge; ## if we have {$x:4}, replace with 4-digit actual value

      $qtext =~ s/\{\$\%$vnm:([0-9])\}/sprintf("%.${1}f",$val*100)/ge; ## if we have {$%x:4}, replace with 4-digit actual value
      $qtext =~ s/\$\%$vnm/sprintf("%.1f",$val*100)/ge; ## if we have $%x, replace with $x*100 actual value

      sub imakeroundexpr { my $rnd= nearest(0.001, $_[0]); return commify($rnd); }  ## typicall, we round to nearest 0.001
      $qtext =~ s/\$$vnm/imakeroundexpr($val)/ge;

      return $qtext;
      ## better {$x:3}  -3.141592 = -3.142; ## $x = -3.1415; ## $$x = -$3.1415; ## ${$x:3} = -$3.142
    }

    $qstn{'Q'} = replonevar($qstn{'Q'}, $vn, $variables{$vn});
    $qstn{'A'} = (defined($qstn{'A'})) ? replonevar($qstn{'A'}, $vn, $variables{$vn}) : "no further detail available\n";

    $qstn{'A'} =~ s/\$-([0-9])/&ndash;\$$1/g;  ## note: we do this only in the answer text, because it is less foreseeable
    $qstn{'Q'} =~ s/\$-([0-9])/&ndash;\$$1/g;  ## it may screw up inside mathjax; leave a space
  }

  return \%qstn;
}

sub commify {
  my $input = shift;
  $input = reverse $input;
  $input =~ s<(\d\d\d)(?=\d)(?!\d*\.)><$1,>g;
  return reverse $input;
}

################################################################################################################################
### test mode
################################################################

if ($0 =~ /EvalOneQuestion.pm/) {

  my $qz= {
	   'N' => 'a test question inside the pm file',
	   'I' => '$ANS=undef ;  $x= rseq(10,20); function sqr($x) { return $x*$x; }; $ANS= sqr($x+1)',
	   'Q' => 'X={$x} is a random integer number between 10 and 20.  Please calculate {$x}+1, square it, and enter it as your answer.',
	   'A' => 'When done, students see long explanation, which can also use vars.  So, here, the correct answer should be {$ANS}.',
	  };
  print "$0:\n".Dumper(evaloneqstn($qz));

  my $q2= {
	   'N' => 'a test question inside the pm file',
	   'I' => '$r=20; $ANS=$r',
	   'Q' => 'What is {$r}?  What is $r?',
	   'A' => 'When done, students see long explanation, which can also use vars.  So, here, the correct answer should be {$ANS}.',
	  };
  print "$0:\n".Dumper(evaloneqstn($q2));
}


################################################################################################################################
### predefined functions
################################################################

1;



################ now come various functions that we want to predefine for use in the equiz mini-language
__DATA__


sub nearest {
  my ($target, $val)=@_;
  my $half = 0.50000000000008;
  return $target * int(($value + $half * $target) / $target);
}



## arg1= start, arg2=end, arg3=add-every-time
sub rseq {
  (defined($_[2])) or $_[2]=1;  ## the default is increment by 1
  ($#_ > 3) and die "perl $0: ERROR: wrong rseq usage with too many arguments: $_\n";
  ($_[0] == $_[1]) and return $_[0];
  (($_[2])*($_[1]-$_[0])>0) or return(undef); ## we have to go the right direction
  my @v=();
  for (my $i=$_[0]; $i<=$_[1]; $i+=($_[2]||1)) {
    push(@v, 0.0+sprintf("%.4f",$i));
  }
  my $choice= int(rand($#v+0.99));
  return $v[$choice];
}


## this sub is made for nice display.  note: it creates an expression like "roundmyfloat(3.1415,'I')", not a number.  otherwise, it may well be cut off


sub pr {
  ## given a list of values, pick one at random,  the list can be
  ## already separated into @_, or it can be comma-separated in one string
  my $string= join(",", @_);
  $string=~ s/\(//g;
  $string=~ s/\)//g;
  my @v= split(/\,/, $string);
  my $choice= int(rand($#v+0.99));
  return $v[$choice];
}


sub mean {
  my $sum=0.0;  for my $i (@_) { $sum+= $i; }
  return $sum/($#_+1);
}

sub var {
  my $mean= mean(@_);
  my $sum=0.0;  for my $i (@_) { $sum+= ($i-$mean)**2; }
  return $sum/($#_+1);
}

sub sd {
  return sqrt(var(@_));
}



sub max { return ($_[0]>$_[1]) ? $_[0] : $_[1]; }
sub min { return ($_[0]>$_[1]) ? $_[1] : $_[0]; }

sub makeroundexpr {
  defined($_[0]) or return "NaN";
  defined($_[1]) or return "roundmyfloat($_[0],'I')";
  return "roundmyfloat($_[0], ". substr($_[1],1,1).")";
}


sub roundmyfloat {
  defined($_[0]) or return "NaN";
  ((!defined($_[1])||($_[1] eq "I"))) and do {
    my $rv= (abs($_[0])>=100) ? sprintf("%.1f", $_[0]) :
      (abs($_[0])>=1) ? sprintf("%.2f", $_[0]) :
      (abs($_[0])>=0.1) ? sprintf("%.3f", $_[0]) : sprintf("%.4f", $_[0]);
    return $rv+0;  ## allow perl to cut off unimportant 0 at the end
  };
  return sprintf("%.".$_[1]."f", $_[0]);
}

sub round {
  return sprintf('%.'.($_[1]||2).'f', $_[0]);
}

sub ln { return log($_[0]); }




sub CumNorm {
  my $x = shift;
  # the percentile under consideration
  my $Pi = 3.141592653589793238;
  # Taylor series coefficients
  my ($a1, $a2, $a3, $a4, $a5) = (0.319381530, -0.356563782, 1.781477937, -1.821255978, 1.330274429);
  # use symmetry to perform the calculation to the right of 0
  my $L = abs($x);
  my $k = 1/( 1 + 0.2316419*$L);
  my $CND = 1 - 1/(2*$Pi)**0.5 * exp(-$L**2/2)* ($a1*$k + $a2*$k**2 + $a3*$k**3 + $a4*$k**4 + $a5*$k**5);
  # then return the appropriate value
  return ($x >= 0) ? $CND : 1-$CND;
}

sub Norm {
  my $x = shift;
  # the percentile under consideration
  my $Pi = 3.141592653589793238;
  return 1.0/sqrt(2*$Pi)*exp(-$x**2/2);
}


################################################################
# a unidimensional bisection solver; further arguments follow
################################################################

sub solveinx {
    my $left= shift;
    my $right= shift;
    my $f= shift;
    ## all the remaining arguments sit in here

    my $leftv= $f->($left, @_);
    my $rightv= $f->($right, @_);

    if ($leftv>$rightv) { my $pp= $left; $left=$right; $right=$pp; $pp=$leftv; $leftv=$rightv; $rightv=$pp;  }

    (($leftv*$rightv)>0) and return "NaN";

    my $numiter=1000;
    while ((--$numiter)>0) {
      my $mid= ($left+$right)/2;
      my $midv= $f->($mid, @_);
      (abs($midv) < 1e-6) and return $mid;
      ($midv*$leftv > 0) and do { $left=$mid; $leftv=$midv; next; };
      $right=$mid; $rightv=$midv;
    }
}


################################################################
## various finance definitions
################################################################

## this one starts with the first cash flow at time 0
sub npv {
  my $r=shift;
  my $sum=0; my $cnt=0;
  foreach (@_) {
    $sum+= $_/(1.0+$r)**$cnt; ++$cnt;
  }
  return $sum;
}


## this one starts with the first cash flow at time 1
sub pv {
  my $r=shift;
  my $sum=0; my $cnt=1;
  foreach (@_) {
    $sum+= $_/(1.0+$r)**$cnt; ++$cnt;
  }
  return $sum;
}

sub annuity { my ($cf, $T, $r) = @_; return ($cf/$r)*( (1- 1/(1+$r)**$T) ); }

sub irr {
  my ($left,$right)= (-1.00+1e-8,1); # start with an IRR between -100% and +100%

  my $leftpv= pv($left, @_); my $rightpv= pv($right, @_);
  ($leftpv*$rightpv<0) or do { $right= 1e3; $rightpv=pv($right, @_); };
  ($leftpv*$rightpv<0) or do { $right= 1e6; $rightpv=pv($right, @_); }; ## or +1000000.00%
  ($leftpv*$rightpv<0) or return "NaN";

  return solveinx($left, $right, \&pv, @_);
}

sub BlackScholes {
  my ($S, $K, $T, $logrf, $plainsd) = @_;
  (defined($S)) or die "perl $0: ERROR: BS: no S\n";  ($S>0) or die "BS: ERROR: bad S0 of $S";
  (defined($K)) or die "perl $0: ERROR: BS: no K\n";  ($K>0) or die "BS: ERROR: bad K0 of $K";
  (defined($T)) or die "perl $0: ERROR: BS: no T\n";  ($T>0) or die "BS: ERROR: bad T0 of $T";
  (defined($logrf)) or die "perl $0: ERROR: BS: no logrf\n";  ($logrf>0) or die "BS: ERROR: bad logrf of $logrf";
  (defined($plainsd)) or die "perl $0: ERROR: BS: no plainsd\n";  ($plainsd>0) or die "BS: ERROR: bad plainsd of $plainsd";

  my $pvx= $K*exp(-$logrf*$T);
  my $sd2exp= $plainsd*sqrt($T);
  my $vol2exp= $sd2exp*$sd2exp;

  my $d1 = ( log($S/$pvx) + $vol2exp/2.0 ) / ( $sd2exp );
  my $d2 = $d1 - $sd2exp;
  return $S * &CumNorm($d1) - $pvx * &CumNorm($d2);
}

sub BlackScholesWrapper {
  ## fifth argument to BS is sd;  we don't know it.
  ## we need to rearrange this.
  my $sd= shift(@_);
  my $cp= pop(@_);
  return BlackScholes(@_, $sd)-$cp;
}

sub BlackScholesIVol {
  my ($left,$right)= (1e-5,99.00); # start with an

  my $leftpv= BlackScholesWrapper($left, @_); my $rightpv= BlackScholesWrapper($right, @_);
  ($leftpv*$rightpv<0) or return "NaN";

  return solveinx($left, $right, \&BlackScholesWrapper, @_);
}

#print "npv = ".npv(0.2,-20,30,50)."\n";
#print "irr = ".irr(-20,30,50)."\n";
#print "BSIVW = ".BlackScholesWrapper(0.55, 80,85,0.13333333,0.0177,2)."\n";
#print "BSIV = ".BlackScholesIVol(80,85,0.13333333,0.0177,2)."\n";

## my @example= (-10,2,2,2);
## print irr( @example ).", ".pv( 0.2, @example )."\n";

## sub isanum { return ($_[0] =~ /^\s*[0-9\.\-]+\s*$/); }
##  sub isaposint { return ($_[0] =~ /^[0-9]+$/); }
## (isaposint($time)) or die "perl $0: Your Time Limit of '$tm' is not a number.\n";

