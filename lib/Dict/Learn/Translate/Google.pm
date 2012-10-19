package Dict::Learn::Translate::Google;

use base qw[ Dict::Learn::Translate ];

use URI::Escape qw[ uri_escape_utf8 ];
use JSON qw[ decode_json from_json ];

use Data::Printer;

use common::sense;

use constant URL => "http://translate.google.com/translate_a/t?client=t&sl=%s&tl=%s&text=%s";

our $VERSION = '0.01';

# sub new {
#   my $class = shift;
#   my $self  = $class->SUPER::new( @_ );
#   $self
# }

sub parse_result {
  my $json = shift;
  my $res;
  if ($json->[0][0][0]) {
    $res->{_} = $json->[0][0][0];
  }
  my $cur_partofspeach;
  for my $item (@{ $json->[1] }) {
    $cur_partofspeach = $item->[0];
    $res->{$cur_partofspeach} = $item->[1];
  }
  $res
}

sub translate {
  my $class = shift;
  my ($from, $to, $text) = @_;
  my $res = $class->SUPER::http_request(
    GET => sprintf URL, $from, $to, uri_escape_utf8( $text )
  );
  return if $res->{code} < 0;
  $res->{content} =~ s/,{2,}/,/g;
  my $json = from_json( $res->{content}, { utf8  => 1 });
  parse_result($json);
}

1;
