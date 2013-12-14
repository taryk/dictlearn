#!/usr/bin/env perl

use common::sense;
use Test::More;

# Ensure a recent version of Test::Pod::Coverage
my $min_tpc = 1.08;
eval "use Test::Pod::Coverage $min_tpc";
plan skip_all => "Test::Pod::Coverage $min_tpc required for testing POD coverage"
    if $@;

# Test::Pod::Coverage doesn't require a minimum Pod::Coverage version,
# but older versions don't recognize some common documentation styles
my $min_pc = 0.18;
eval "use Pod::Coverage $min_pc";
plan skip_all => "Pod::Coverage $min_pc required for testing POD coverage"
    if $@;

# BUILD, BUILDARGS, and FOREIGNBUILDARGS can be w/o POD
my $trustme = { trustme => [qr/^(BUILD|BUILDARGS|FOREIGNBUILDARGS)$/] };

# all_pod_coverage_ok($trustme);

# Get a list of all modules inside lib/
my @modules = all_modules( 'lib' );

plan tests => scalar @modules;

for (@modules) {
    pod_coverage_ok($_, $trustme);
}
