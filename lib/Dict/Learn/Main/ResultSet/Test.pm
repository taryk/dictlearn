package Dict::Learn::Main::ResultSet::Test 0.1;
use base 'DBIx::Class::ResultSet';

use namespace::autoclean;

use common::sense;

use Data::Printer;

sub export_data {
    my ($self) = @_;
    my $rs = $self->search({}, {});
    $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
    $rs->all();
}

sub import_data {
    my ($self, $data) = @_;
    $self->populate($data);
    return 1;
}

sub clear_data {
    my ($self) = @_;
    $self->delete_all();
}

1;
