package Dict::Learn::Import 0.1;

use JSON;
use IO::File;

use common::sense;

use Data::Printer;

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
  if (my $fh = IO::File->new($filename, 'r'))
  {
    my $data = decode_json(do { local $/; <$fh> } );
    my $db = $main::ioc->lookup('db');
    while ( my ($json_key, $rset_name) = each %{ +TABLE_MAP } ) {
      $db->schema->resultset($rset_name)->import_data($data->{$json_key})
        if defined $data->{$json_key} and
               ref $data->{$json_key} eq 'ARRAY';
    }
  }
}

1;
