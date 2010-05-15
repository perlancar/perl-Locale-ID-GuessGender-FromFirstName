package Locale::ID::GuessGender::FromFirstName::google;

use strict;
use warnings;
use REST::Google::Search;

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

Whether the algorithm succeeds. Might return 0 if can't contact
Google, for example.

=item result => "M" or "F" or "both" or "neither" or undef.

=item gender_ratio => FRACTION

=item min_gender_ratio => FRACTION

=item guess_confidence => FRACTION

=item num_results_bapak => INT

=item num_results_ibu => INT

=back

=cut

sub guess_gender {
    my $opts;
    if (@_ && ref($_[0]) eq 'HASH') {
        $opts = shift;
    } else {
        $opts = {};
    }
    die "Please specify at least 1 name" unless @_;

    REST::Google::Search->http_referer(
        "http://search.cpan.org/dist/Locale-ID-GenderGuess-FromFirstName/");

    my @res;
    for my $name (@_) {
        do { push @res, undef; next } unless defined($name);
        my $res = { success => 0 };

        {
            my $r;
            for my $c ([num_results_bapak => qq["bapak $name"]],
                       [num_results_ibu   => qq["ibu $name"]]) {
                $r = REST::Google::Search->new(q=>$c->[1]);
                if (!$r) {
                    $res->{error} = "REST::Google::Search returns".
                        " nothing (q=$c->[1])";
                    last;
                }
                if ($r->{responseStatus} != 200) {
                    $res->{error} = "REST::Google::Search returns".
                        " HTTP error $r->{responseStatus} (q=$c->[1])";
                    last;
                }
                if (!$r->{responseData}) {
                    $res->{error} = "REST::Google::Search does not".
                        " return responseData (q=$c->[1])";
                    last;
                }
                $res->{$c->[0]} = $r->{responseData}{cursor}->
                                      {estimatedResultCount} // 0;
            }
            last if $res->{error};
        }

        if (!$res->{error}) {
            $res->{success} = 1;
            my ($b, $i) = ($res->{num_results_bapak}, $res->{num_results_ibu});
            my $tot = $b+$i;
            my $ratio = (!$b && !$i) ? 0 :
                ($b > $i ? $b/($b+$i) : $i/($b+$i));
            my $min_ratio = $tot < 10 ? 2/(1+2) :
                ($tot < 100 ? 2/(1+2) : $tot < 1000 ? 2/(1+2) : 2/(1+2));
            $res->{min_gender_ratio} = $min_ratio;
            $res->{gender_ratio} = $ratio;
            if (!$tot) {
                $res->{result} = undef;
                $res->{guess_confidence} = 0;
            } else {
                $res->{result} =
                    $ratio < $min_ratio ? "both" : ($b > $i ? "M" : "F");
                $res->{guess_confidence} = $tot < 10 ? 0.75 : 0.9;
            }
        }
        push @res, $res;
    }
    @res;
}

1;
