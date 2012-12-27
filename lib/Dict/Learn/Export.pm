package Dict::Learn::Export 0.1;

use JSON;
use IO::File;
use POSIX qw(strftime);

use common::sense;

use Data::Printer;

use constant EXPORT_FILENAME => 'export.%d.json';

sub new {
  my $class = shift;
  my $self  = bless { } => $class;

  $self
}

sub do {
  my ($self, $filename) = @_;
  my $db = $main::ioc->lookup('db');
  my $export = encode_json({
    words               => $db->select_all_words(),
    words_xref          => $db->select_all_words_xref(),
    examples            => $db->select_all_examples(),
    examples_xref       => $db->select_all_examples_xref(),
    words_examples_xref => $db->select_all_words_examples_xref(),
  });
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
