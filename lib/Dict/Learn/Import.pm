package Dict::Learn::Import;

use Const::Fast;
use Data::Printer;
use IO::File;
use JSON;

use common::sense;

use Database;

=head1 NAME

Dict::Learn::Import

=head1 DESCRIPTION

TODO add description

=cut

const my $TABLE_MAP => {
    words             => 'Word',
    words_xref        => 'Words',
    test_session      => 'TestSession',
    test_session_data => 'TestSessionData'
};

=head1 METHODS

=head2 new

TODO add description

=cut

sub new {
    my $class = shift;
    my $self = bless {} => $class;

    return $self;
}

=head2 do

TODO add description

=cut

sub do {
    my ($self, $filename) = @_;
    if (my $fh = IO::File->new($filename, 'r')) {
        my $data = decode_json(
            do { local $/; <$fh> }
        );
        while (my ($json_key, $rset_name) = each %$TABLE_MAP) {
            Database->schema->resultset($rset_name)
                ->import_data($data->{$json_key})
                if defined $data->{$json_key}
                and ref $data->{$json_key} eq 'ARRAY';
        }
    }
}

1;
