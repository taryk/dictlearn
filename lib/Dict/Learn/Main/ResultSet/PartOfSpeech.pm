package Dict::Learn::Main::ResultSet::PartOfSpeech 0.1;
use base 'DBIx::Class::ResultSet';

use namespace::autoclean;
use common::sense;

use Data::Printer;

=head1 NAME

Dict::Learn::Main::ResultSet::PartOfSpeech

=head1 DESCRIPTION

TODO add description

=head1 FUNCTIONS

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

=head2 select

TODO add description

=cut

sub select {
    my ($self, %params) = @_;
    my $args = {};
    if ($params{name}) {
        $args->{-or} = [
            name_orig => {-like => $params{name}},
            name_tr   => {-like => $params{name}},
        ];
    }
    my $rs = $self->search($args, {order_by => {-asc => 'partofspeech_id'}});
    $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
    $rs->all();
}

1;
