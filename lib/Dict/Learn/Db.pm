package Dict::Learn::Db 0.1;

use common::sense;
use namespace::autoclean;

use Data::Printer;

use Class::XSAccessor
    accessors => [ qw| schema | ];

sub new {
  my $class  = shift;
  my $self = bless {} => $class;
  $self->schema( shift );
  $self
}

1;

