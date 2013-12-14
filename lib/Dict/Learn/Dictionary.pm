package Dict::Learn::Dictionary 0.1;

use Data::Printer;

use common::sense;
use namespace::autoclean;

use Database;

my $singleton;

=head1 NAME

Dict::Learn::Dictionary

=head1 DESCRIPTION

TODO add description

=head1 FUNCTIONS

=head2 new

TODO add description

=cut

sub new {
    my $class = shift;

    my $self = bless {} => $class;
    $self->{dicts}   = {};
    $self->{dict_id} = undef;
    $self->{cb}      = [];

    $self;
}

=head2 singleton

TODO add description

=cut

sub singleton { $singleton ||= __PACKAGE__->new }

=head2 clear

TODO add description

=cut

sub clear { undef $singleton }

=head2 all

TODO add description

=cut

sub all {
    my $self = shift;

    $self = $self->singleton unless ref $self;
    $self->{dicts} = {};
    for (Database->schema->resultset('Dictionary')->get_all()) {
        $self->{dicts}{ $_->{dictionary_id} } = $_;
    }

    return $self->{dicts};
}

=head2 set

TODO add description

=cut

sub set {
    my ($self, $id) = @_;

    $self = $self->singleton unless ref $self;
    $self->{dict_id} = $id;
    for (@{ $self->{cb} }) { $_->($self) }
}

=head2 cb

TODO add description

=cut

sub cb {
    my ($self, $cb) = @_;

    $self = $self->singleton unless ref $self;
    unless (ref $cb eq 'CODE') {
        warn 'Wrong "cb" type';
        return;
    }

    push @{ $self->{cb} } => $cb;

    # Call the coderef immediately if dict_id is already set
    $cb->($self) if defined $self->{dict_id};
}

=head2 get

TODO add description

=cut

sub get {
    my ($self, $id) = @_;

    $self = $self->singleton unless ref $self;
    defined $self->{dicts}{$id} ? $self->{dicts}{$id} : undef;
}

=head2 curr

TODO add description

=cut

sub curr {
    my $self = shift;

    $self = $self->singleton unless ref $self;
    $self->{dicts}{ $self->{dict_id} };
}

=head2 curr_id

TODO add description

=cut

sub curr_id {
    shift->singleton->{dict_id}
}

=head2 add

TODO add description

=cut

sub add {
    my ($self, %params) = @_;

    $self = $self->singleton unless ref $self;

    # @TODO implement
}

=head2 delete

TODO add description

=cut

sub delete {
    my ($self, $id) = @_;

    $self = $self->singleton unless ref $self;

    # @TODO implement
}

1;
