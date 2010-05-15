#!perl -T

use strict;
use warnings;
use Test::More tests => 4;

use Locale::ID::GuessGender::FromFirstName qw(guess_gender);

SKIP: {
    skip "only for release testing", 4 unless $ENV{RELEASE_TESTING};

    is((guess_gender({algos=>['google']}, "budi"))[0]{result}, "M", "budi");
    is((guess_gender({algos=>['google']}, "lusi"))[0]{result}, "F", "lusi");

    my $res;

    ($res) = guess_gender({algos=>['common', 'google']}, "kasur");
    ok($res->{result} eq 'F' && $res->{algo} eq 'google', "kasur (common X -> google V)");
    ($res) = guess_gender({try_all=>1, algos=>['common', 'google']}, "budi");
    ok($res->{result} eq 'M' && $res->{algo} eq 'common' && @{$res->{algo_res}} == 2, "budi (common V -> google V)");
}

