package Dict::Learn::Dictionary 0.1;

use Data::Printer;

use common::sense;
use namespace::autoclean;

my $singleton;

sub new {
  my $class = shift;
  my $self = bless { } => $class;
  $self->{dicts}   = { };
  $self->{dict_id} = undef;
  $self->{cb}      = [ ];
  $self
}

sub singleton { $singleton ||= __PACKAGE__->new }

sub all {
  my $self = shift;
  $self = $self->singleton unless ref $self;
  $self->{dicts} = { };
  for ( $main::ioc->lookup('db')->get_dictionaries() )
  {
    $self->{dicts}{ $_->{dictionary_id} } = $_;
  }
  $self->{dicts}
}

sub set {
  my ($self, $id) = @_;
  $self = $self->singleton unless ref $self;
  $self->{dict_id} = $id;
  for (@{ $self->{cb} }) { $_->($self) }
}

sub cb {
  my ($self, $cb) = @_;
  $self = $self->singleton unless ref $self;
  unless (ref $cb eq 'CODE') {
    warn "Wrong `cb` type";
    return
  }
  push @{ $self->{cb} } => $cb
}

sub get {
  my ($self, $id) = @_;
  $self = $self->singleton unless ref $self;
  defined $self->{dicts}{$id} ? $self->{dicts}{$id} : undef
}

sub curr {
  my $self = shift;
  $self = $self->singleton unless ref $self;
  $self->{dicts}{ $self->{dict_id} }
}

sub curr_id { shift->singleton->{dict_id} }

sub add {
  my ($self, %params) = @_;
  $self = $self->singleton unless ref $self;
  # @TODO implement
}

sub delete {
  my ($self, $id) = @_;
  $self = $self->singleton unless ref $self;
  # @TODO implement
}

1;
