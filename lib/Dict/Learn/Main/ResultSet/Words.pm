package Dict::Learn::Main::ResultSet::Words;
use base 'DBIx::Class::ResultSet';

use namespace::autoclean;
use common::sense;

use Data::Printer;

=head1 NAME

Dict::Learn::Main::ResultSet::Words

=head1 DESCRIPTION

TODO add description

=head1 METHODS

=head2 export_data

TODO add description

=cut

sub export_data {
    my ($self) = @_;
    my $rs = $self->search({}, {});
    $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
    $rs->all();
}

=head2 import_data

TODO add description

=cut

sub import_data {
    my ($self, $data) = @_;
    $self->populate($data);
    return 1;
}

=head2 clear_data

TODO add description

=cut

sub clear_data {
    my ($self) = @_;
    $self->delete_all();
}

1;
