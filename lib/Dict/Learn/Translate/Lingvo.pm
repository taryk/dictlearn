package Dict::Learn::Translate::Lingvo 0.1;

use base qw[ Dict::Learn::Translate ];

use Data::Printer;
use Encode qw(encode decode);
use JSON qw[ decode_json from_json ];
use Mojo::DOM;
use URI::Escape qw[ uri_escape_utf8 ];
use List::MoreUtils 'any';

use common::sense;

sub URL { 'http://www.lingvo.ua/ru/Translate/%s-%s/%s' }

sub PARTSOFSPEACH {
    {
        n    => 'noun',            # іменник
        a    => 'adjective',       # прикметник
        num  => 'numeral',         # числівник
        pron => 'pronoun',         # займенник
        v    => 'verb',            # дієслово
        adv  => 'adverb',          # прислівник
        prep => 'preposition',     # прийменник
        cj   => 'conjunction',     # сполучник
        int  => 'interjection',    # вигук
        'p. p.' =>
            'participle',    # дієприкметник (past participle)
    }
}

{
    my $curr = {
        partofspeach => '_',
        variant      => 'I'
    };

    sub parse_item {
        my $res = {
            variant      => undef,
            partofspeach => undef,
            words        => []
        };

        given ($_[0]->attrs->{class}) {
            when ('P') {
                my $span = $_[0]->find('span')->first;
                return unless $span;
                my $text = $span->all_text;

                given ($span->attrs->{class}) {
                    when ('Bold') {
                        if ($text =~ /^(?<variant>[IVXLMC]+)\s*$/x) {
                            $curr->{variant} = $+{variant};
                        }
                    }
                    when ('l-article__abbrev') {
                        # if ($text =~ /^(n|v|)$/)
                        say "unknown: '$text'" unless PARTSOFSPEACH->{$text};
                        $curr->{partofspeach} = PARTSOFSPEACH->{$text}
                            // 'noun';
                    }
                }
            }
            when ('P1') {
                if (    $_[0]->find('span.translation')->size == 0
                    and $_[0]->find('span.l-article__abbrev')->size >= 1)
                {
                    my $text = $_[0]->span->all_text;
                    if (any { $text eq $_ } keys %{+PARTSOFSPEACH}) {
                        $curr->{partofspeach} = PARTSOFSPEACH->{$text};
                        return;
                    }
                }
                my $words_line = $_[0]->all_text =~ s/^\d+[)]\s+//r;
                my $words;
                for my $word (split /\s*;\s*/ => $words_line) {
                    my $word_entry;
                    if ($word
                        =~ s/^\s*[(]\s*(?<preposition>[^)]+)\s*[)]\s*//iusx)
                    {
                        $word_entry->{prep}
                            = [split /\s*,\s*/ => $+{preposition}];
                    }
                    if ($word =~ s/^\s*(?<category>[^. ]+)[.]\s*//iusx) {
                        $word_entry->{category} = $+{category};
                    }
                    if ($word =~ s/\s*[(]\s*(?<note>[^)]+)\s*[)]\s*$//iusx) {
                        $word_entry->{note} = $+{note};
                        chomp($word_entry->{note});
                    }
                    $word_entry->{word} = $word;
                    push @$words => $word_entry;
                }
                $res = {
                    variant      => $curr->{variant},
                    partofspeach => $curr->{partofspeach},
                    words        => $words,
                };
            }
        }
    }
}

sub translate {
    my $class = shift;

    my ($from, $to, $text) = @_;
    my $res = $class->SUPER::http_request(
        GET => sprintf(URL, $from, $to, uri_escape_utf8($text)),
        {   'Cookie' =>
                'ClickedOnTranslationsCount=2; '
                . 'xst=E33FE85E8DE54DC5B7CC20A2F0EEDD33; '
                . 'LastSearchRequest=08.06.2013 20:37; rateUs_cnt_1_8=54; '
                . 'rateUs_later_1_8=true; tz=120; uiCulture=uk; '
                . 'profile=searchsrclang:S:en:searchtgtlang:S:uk;',
            'Referer   ' => 'http://www.lingvo.ua/',
            'User-Agent' =>
                'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.11 (KHTML, like Gecko)',
            'Accept-Charset' => 'ISO-8859-1,utf-8;q=0.7,*;q=0.3',
        }
    );

    # return if $res->{code} < 0;
    my $dom = Mojo::DOM->new(decode('UTF-8', $res->{content}));
    my $tr_res;
    if (my $res = $dom->at('div.js-article-html')) {
        # p($res->to_xml);
        # $res->all_text(0);
        given ($res->find('p')->size) {
            when (1) {
                if (my $parsed_item = parse_item $res->p) {
                    push @{$tr_res->{$parsed_item->{variant}}
                            {$parsed_item->{partofspeach}}},
                        $parsed_item->{words};
                }
            }
            when ($_ > 1) {
                for my $item ($res->p->each) {
                    if (my $parsed_item = parse_item $item) {
                        push @{$tr_res->{$parsed_item->{variant}}
                                {$parsed_item->{partofspeach}}},
                            $parsed_item->{words};
                    }
                }
            }
        }
    }

    return $tr_res;
}

1;
