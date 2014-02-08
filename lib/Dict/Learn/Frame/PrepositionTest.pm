package Dict::Learn::Frame::PrepositionTest;

use Wx qw[:everything];
use Wx::Event qw[:everything];

use Data::Printer;

use Moose;
use MooseX::NonMoose;
extends 'Wx::Panel';

use Carp qw[ croak confess ];
use Const::Fast;

use common::sense;

use Dict::Learn::Dictionary;

const my $TEST_ID => 2;

=head1 NAME

Dict::Learn::Frame::TranslationTest

=head1 DESCRIPTION

TODO add description

=head1 ATTRIBUTES

=cut

=head1 METHODS

=cut

sub FOREIGNBUILDARGS {
    my ($class, $parent, @args) = @_;

    return @args;
}

sub BUILDARGS {
    my ($class, $parent) = @_;

    return { parent => $parent };
}

sub BUILD {
    my ($self, @args) = @_;

}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
