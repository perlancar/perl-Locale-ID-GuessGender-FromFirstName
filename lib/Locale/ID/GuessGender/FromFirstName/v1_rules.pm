package Locale::ID::GuessGender::FromFirstName::v1_rules;

use strict;
use warnings;

# VERSION

# XXX extract from common list instead of wild guessing
my @rules = (
    [qr/.o$/,      M => 0.98],
    [qr/.i$/,      F => 0.60],
    [qr/.ini$/,    F => 0.90],
    [qr/.d$/,      M => 0.85],
    [qr/.wan$/,    M => 0.99],
    [qr/.wati$/,   F => 0.99],
    [qr/.us$/,     M =>  0.7],
);

sub guess_gender {
    my $opts;
    if (@_ && ref($_[0]) eq 'HASH') {
        $opts = shift;
    } else {
        $opts = {};
    }
    die "Please specify at least 1 name" unless @_;

    my @res;
    for my $name (@_) {
        do { push @res, undef; next } unless defined($name);
        my $res = { success => 0 };

        my $num_match = 0;
        my $m = 1;
        my $f = 1;
        my $min_ratio = 0.75;
        for my $rule (@rules) {
            $name =~ $rule->[0] or next;
            $num_match++;
            if ($rule->[1] eq 'M') {
                $m *= $rule->[2];
                $f *= (1-$rule->[2]);
            } else {
                $f *= $rule->[2];
                $m *= (1-$rule->[2]);
            }
        }
        if ($num_match) {
            $res->{success} = 1;
            $res->{num_rules} = $num_match;
            $res->{min_gender_ratio} = $min_ratio;
            my $r = $m > $f ? $m/($m+$f) : $f/($m+$f);
            $res->{result} = $r < $min_ratio ? "both" : ($m > $f ? "M" : "F");
            $res->{gender_ratio} = $r;
            $res->{guess_confidence} = $r;
        } else {
            $res->{error} = "No heuristic rules matched";
        }
        push @res, $res;
    }
    @res;
}

1;
# ABSTRACT: v1_rules

=head1 FUNCTIONS

=head2 guess_gender([OPTS, ]FIRSTNAME...) => RES, ...

Guess the gender of given first name(s). An optional hashref OPTS can
be given as the first argument. Valid pair for OPTS:

=over 4

=back

Will return a result hashref RES for each given input. Known pair of
RES:

=over 4

=item success => BOOL

Whether the algorithm succeeds.

=item result => "M" or "F" or "both" or "neither" or undef.

=item gender_ratio => FRACTION

=item min_gender_ratio => FRACTION

=item guess_confidence => FRACTION

=item sample_ratio => INT

=back

=cut
