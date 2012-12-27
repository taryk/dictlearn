package Dict::Learn::Import 0.1;

use JSON;
use IO::File;

use common::sense;

use Data::Printer;

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
    $db->import_words($data->{words})
      if defined $data->{words} and
             ref $data->{words} eq 'ARRAY';
    $db->import_words_xref($data->{words_xref})
      if defined $data->{words_xref} and
             ref $data->{words_xref} eq 'ARRAY';
    $db->import_examples($data->{examples})
      if defined $data->{examples} and
             ref $data->{examples} eq 'ARRAY';
    $db->import_examples_xref($data->{examples_xref})
      if defined $data->{examples_xref} and
             ref $data->{examples_xref} eq 'ARRAY';
    $db->import_words_examples_xref($data->{words_examples_xref})
      if defined $data->{words_examples_xref} and
             ref $data->{words_examples_xref} eq 'ARRAY';
  }
}

1;
