package Dict::Learn::Translate;

use HTTP::Request;
use LWP::UserAgent;
use JSON qw[ encode_json to_json decode_json from_json ];

use common::sense;

use Data::Printer;

use constant USERAGENT => 'Mozilla/5.0';

sub new {
  my $class = shift;
  my $self  = bless {
    using    => 'Google',
    from     => 'en',
    to       => 'uk',
    tplugins => [],
    @_
  } => $class;
  $self->preload_tplugins;
  $self
}

sub preload_tplugins {
  my $self = shift;
  my $path = substr $INC{'Dict/Learn/Translate.pm'},
             0, length($INC{'Dict/Learn/Translate.pm'}) - 3;
  for my $tplugin (glob $path.'/*')
  {
    next unless $tplugin =~ m[/(?<tplugin>\w+)\.pm$]i;
    eval {
      require $tplugin;
      1
    } or do {
      printf "%s wrong plugin\n" => $tplugin;
      next
    };
    push @{$self->{tplugins}} => $+{tplugin};
  }
}

sub do {
  my $self = shift;
  my ($from, $to, $text) = @_;
  $self->from($from)->to($to);
  my $tr_class = __PACKAGE__."::".$self->{using};
  unless (grep { $_ eq $self->{using} } @{ $self->{tplugins} })
  {
    printf "'%s' undef translate engine\n" => $self->{using};
    return;
  }
  $tr_class->translate($self->{from}, $self->{to}, $text);
}

sub from {
  my $self = shift;
  $self->{from} = shift;
  $self
}

sub to {
  my $self = shift;
  $self->{to} = shift;
  $self
}

sub using {
  my $self = shift;
  $self->{using} = shift;
  $self
}

sub http_request {
  my ($self, $method, $url, $headers, $content) = @_;
  my $h = HTTP::Headers->new();
  $h->header( %$headers )
    if $headers and ref $headers eq 'HASH';
  my $json;
  if ($content and ref($content) =~ /^ARRAY|HASH$/) {
    $json = encode_json($content);
  }
  my $req = HTTP::Request->new($method => $url, $h, $json || $content);
  my $res = LWP::UserAgent->new( agent => USERAGENT )->request( $req );
  if ($res->is_success) {
    { code    => $res->code,
      content => $res->content }
  }
  else {
    { code    =>  -1,
      content => $res->status_line }
  }
}

1;

