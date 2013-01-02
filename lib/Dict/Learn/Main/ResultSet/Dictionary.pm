package Dict::Learn::Main::ResultSet::Dictionary 0.1;
use base 'DBIx::Class::ResultSet';

use namespace::autoclean;

use common::sense;

use Data::Printer;

sub export_data {
  my ($self) = @_;
  my $rs = $self->search({ }, { });
  $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
  $rs->all()
}

sub import_data {
  my ($self, $data) = @_;
  $self->populate($data);
  return 1
}

sub clear_data {
  my ($self) = @_;
  $self->delete_all()
}

sub get_all {
  my $self = shift;
  my $params;
  if (defined(my $dictionary_id = shift)) {
    $params = { dictionary_id => $dictionary_id };
  }
  my $rs = $self->search($params => {
    prefetch => [ qw| language_orig_id language_tr_id | ],
  });
  $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
  $rs->all()
}

1;
