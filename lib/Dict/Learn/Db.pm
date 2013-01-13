package Dict::Learn::Db 0.1;

use common::sense;
use namespace::autoclean;

use Data::Printer;

use constant REQ_TABLES =>
  [qw| word word_xref example example_xref word_example_xref
       dictionary wordclass language test test_session test_session_data
     |];

use Class::XSAccessor
    accessors => [ qw| schema | ];

sub new {
  my $class = shift;
  my $self = bless {} => $class;
  $self->schema( shift );
  $self
}

sub check_tables {
  my $self = shift;
  say "Checking DB...";
  my @tables = grep { $_->[0] eq 'main' }
    map { [ (/^\"(\w+)\"\.\"(\w+)\"$/) ] }
    $self->schema->storage->dbh->tables();
  for my $req_table (@{ +REQ_TABLES }) {
    return unless grep { $req_table eq $_->[1]  } @tables;
  }
  1
}

1;

