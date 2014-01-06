package Dict::Learn::Translate::Google;
use base qw[ Dict::Learn::Translate ];

use Const::Fast;
use Data::Printer;
use JSON qw[ decode_json from_json ];
use URI::Escape qw[ uri_escape_utf8 ];

use common::sense;

=head1 NAME

Dict::Learn::Translate::Google

=head1 DESCRIPTION

TODO add description

=cut

const my $URL =>
    'http://translate.google.com/translate_a/t?client=t&sl=%s&tl=%s&text=%s';

=head1 METHODS

=head2 parse_result

TODO add description

=cut

sub parse_result {
    my $json = shift;

    my $res;
    if ($json->[0][0][0]) {
        $res->{_} = $json->[0][0][0];
    }
    my $cur_partofspeech;
    for my $item (@{$json->[1]}) {
        $cur_partofspeech = $item->[0];
        $res->{$cur_partofspeech} = [map { {word => $_} } @{$item->[1]}];
    }

    return $res;
}

=head2 translate

TODO add description

=cut

sub translate {
    my $class = shift;

    my ($from, $to, $text) = @_;
    my $res = $class->SUPER::http_request(
        GET => sprintf $URL,
        $from, $to, uri_escape_utf8($text)
    );
    return if $res->{code} < 0;
    $res->{content} =~ s/,{2,}/,/g;
    my $json = from_json($res->{content}, {utf8 => 1});

    return { I => parse_result($json) };
}

1;
