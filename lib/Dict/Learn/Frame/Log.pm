package Dict::Learn::Frame::Log;

use Wx qw[:everything];
use Wx::Event qw[:everything];

use Moose;
use MooseX::NonMoose;
extends 'Wx::Panel';

use Data::Printer;

use common::sense;

=head1 NAME

Dict::Learn::Frame::Log

=head1 DESCRIPTION

TODO add description

=head1 ATTRIBUTES

=head2 parent

TODO add description

=cut

has parent => (
    is  => 'ro',
    isa => 'Dict::Learn::Frame',
);

=head2 vbox

TODO add description

=cut

has vbox => (
    is         => 'ro',
    isa        => 'Wx::BoxSizer',
    lazy_build => 1,
);

sub _build_vbox {
    my $self = shift;
    
    my $vbox = Wx::BoxSizer->new(wxVERTICAL);

    return $vbox;
}

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

    $self->SetSizer($self->vbox);
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
