package Dict::Learn::Export 0.1;

use JSON;
use IO::File;
use POSIX qw(strftime);

use common::sense;

use Data::Printer;

use constant EXPORT_FILENAME => 'export.%d.json';

use constant {
  TABLE_MAP => { words               => 'Word',
                 words_xref          => 'Words',
                 examples            => 'Example',
                 examples_xref       => 'Examples',
                 words_examples_xref => 'WordExample',
  }
};

sub new {
  my $class = shift;
  my $self  = bless { } => $class;

  $self
}

sub do {
  my ($self, $filename) = @_;
  my $db = $main::ioc->lookup('db');
  my $data = {};
  while ( my ($json_key, $rset_name) = each %{ +TABLE_MAP } ) {
    $data->{$json_key} = [ $db->schema->resultset($rset_name)->export_data() ];
  }
  my $export = encode_json($data);
  $filename //= sprintf(EXPORT_FILENAME, strftime('%Y%m%d%H%M%S', localtime));
  if (my $fh = IO::File->new('> '.$filename))
  {
    print $fh $export;
    $fh->close;
    return $filename;
  } else {
    return;
  }
}

1;
