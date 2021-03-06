package Dict::Learn::Export;

use Const::Fast;
use Data::Printer;
use IO::File;
use JSON;
use POSIX 'strftime';

use common::sense;

use Database;

=head1 NAME

Dict::Learn::Export

=head1 DESCRIPTION

TODO add description

=cut

const my $EXPORT_FILENAME => 'export.%d.json';

const my $TABLE_MAP => {
    words               => 'Word',
    words_xref          => 'Words',
    test_session        => 'TestSession',
    test_session_data   => 'TestSessionData'
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
    my $data = {};
    while (my ($json_key, $rset_name) = each %$TABLE_MAP) {
        $data->{$json_key}
            = [Database->schema->resultset($rset_name)->export_data()];
    }
    my $export = encode_json($data);
    $filename //=
        sprintf($EXPORT_FILENAME, strftime('%Y%m%d%H%M%S', localtime));
    if (my $fh = IO::File->new('> ' . $filename)) {
        print $fh $export;
        $fh->close;
        return $filename;
    }
    else {
        return;
    }
}

1;
