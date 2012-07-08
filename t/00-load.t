#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Dict::Learn' ) || print "Bail out!\n";
}

diag( "Testing Dict::Learn $Dict::Learn::VERSION, Perl $], $^X" );
