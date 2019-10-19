package EQ::Quiz;

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

use v5.20;

use strict;
use warnings;

use Scalar::Util qw/looks_like_number/;

sub calculate_results {
    my $form_data = shift;

    my @questions_results;

    my $qnames_str = EQ::Safeeval::decryptmsg($form_data->{'q-A-*'});
    return unless $qnames_str;

    my $qcount = split(/\s*,\s*/, $qnames_str);
    foreach my $qnum ( 1..$qcount ) {
        my $qname =  $form_data->{"q-N-$qnum"};

        my $long_answer   = eval{ EQ::Safeeval::decryptmsg( $form_data->{"q-A-$qnum"} ) };
        my $precision     = eval{ EQ::Safeeval::decryptmsg( $form_data->{"q-P-$qnum"} ) } || 0;
        my $question_text = $form_data->{"q-Q-$qnum"};

        my $student_answer = $form_data->{"q-stdnt-$qnum"} // '';
        ( my $cleaned_answer = $student_answer ) =~ tr/\-0-9.,//cd;
        $cleaned_answer =~ s/,/./g;
        $cleaned_answer = 0 unless looks_like_number($cleaned_answer);

        push @questions_results,  {
            name           => $qname,
            number         => $qnum,
            is_correct     => ( length($short_answer) ? _is_similar( $precision, $cleaned_answer, $short_answer ) : '0' ),
            precision      => $precision,
            student_answer => $student_answer,
            delta_answer   => sprintf("%7.7f", abs($student_answer - $short_answer)),
            short_answer   => sprintf("%.6f",$short_answer),
            long_answer    => $long_answer,
            question_text  => $question_text
        };
    }

    return [ sort { $a->{number} <=> $b->{number} } @questions_results ];
}

sub _is_similar {
    my ($precision, $a1, $a2) = @_;

    if ( !$precision ) {
        if ( abs($a1) > 10.0 ) {
            $precision = 1;
        }
        elsif ( abs($a1) > 1.0 ) {
            $precision = 0.1;
        }
        else {
            $precision = 0.01;
        }
    }

    my $adelta = abs($a1 - $a2);

    return abs($adelta) <= $precision;
}

1;
