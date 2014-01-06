package Dict::Learn::Main::ResultSet::Dictionary;
use base 'DBIx::Class::ResultSet';

use namespace::autoclean;
use common::sense;

use Data::Printer;

=head1 NAME

Dict::Learn::Main::ResultSet::Dictionary

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

=head2 get_all

TODO add description

=cut

sub get_all {
    my $self = shift;
    my $params;
    if (defined(my $dictionary_id = shift)) {
        $params = {dictionary_id => $dictionary_id};
    }
    my $rs = $self->search(
        $params => {prefetch => [qw| language_orig_id language_tr_id |],});
    $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
    $rs->all();
}

1;
