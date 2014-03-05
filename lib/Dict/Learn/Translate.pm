package Dict::Learn::Translate;

use Const::Fast;
use Data::Printer;
use HTTP::Request;
use JSON qw(encode_json to_json decode_json from_json);
use LWP::UserAgent;
use List::Util 'none';

use common::sense;

=head1 NAME

Dict::Learn::Translate

=head1 DESCRIPTION

TODO add description

=cut

const my $USERAGENT => 'Mozilla/5.0';

=head1 METHODS

=head2 new

TODO add description

=cut

sub new {
    my $class = shift;

    my $self  = bless {
        using    => undef,
        from     => 'en',
        to       => 'uk',
        tplugins => [],
        @_
    } => $class;
    $self->preload_tplugins;

    return $self;
}

=head2 preload_tplugins

TODO add description

=cut

sub preload_tplugins {
    my $self = shift;

    my $path = substr $INC{'Dict/Learn/Translate.pm'},
        0, length($INC{'Dict/Learn/Translate.pm'}) - 3;
    for my $tplugin (glob $path . '/*') {
        next unless $tplugin =~ m{/(?<tplugin>\w+)[.]pm$}ix;
        eval {
            require $tplugin;
            1;
        } or do {
            printf "%s wrong plugin\n" => $tplugin;
            next;
        };
        push @{$self->{tplugins}} => $+{tplugin};
    }
}

=head2 get_backends_list

TODO add description

=cut

sub get_backends_list {
    my $self = shift;

    $self->{tplugins};
}

=head2 do

TODO add description

=cut

sub do {
    my $self = shift;

    my ($from, $to, $text) = @_;
    $self->from($from)->to($to);
    my $tr_class = __PACKAGE__ . '::' . $self->{using};
    if (none { $_ eq $self->{using} } @{$self->{tplugins}}) {
        printf "'%s' undef translate engine\n" => $self->{using};
        return;
    }
    $tr_class->translate($self->{from}, $self->{to}, $text);
}

=head2 from

TODO add description

=cut

sub from {
    my $self = shift;

    $self->{from} = shift;

    return $self;
}

=head2 to

TODO add description

=cut

sub to {
    my $self = shift;

    $self->{to} = shift;

    return $self;
}

=head2 using

TODO add description

=cut

sub using {
    my $self = shift;

    $self->{using} = shift;

    return $self;
}

=head2 http_request

TODO add description

=cut

sub http_request {
    my ($self, $method, $url, $headers, $content) = @_;

    my $h = HTTP::Headers->new();
    $h->header(%$headers)
        if $headers and ref $headers eq 'HASH';
    my $json;
    if ($content and ref($content) ~~ ['ARRAY', 'HASH']) {
        $json = encode_json($content);
    }
    my $req = HTTP::Request->new($method => $url, $h, $json || $content);
    my $res = LWP::UserAgent->new(agent => $USERAGENT)->request($req);
    if ($res->is_success) {
        return {
            code    => $res->code,
            content => $res->content
        };
    } else {
        return {
            code    => -1,
            content => $res->status_line
        };
    }
}

1;

