package Dict::Learn::Translate::Promt;

use base qw[ Dict::Learn::Translate ];

use URI::Escape qw[ uri_escape_utf8 ];
use JSON qw[ decode_json from_json ];
use common::sense;

use Data::Printer;

use constant {
  URL => "http://www.translate.ru/services/TranslationService.asmx/GetTranslation",
  PARTSOFSPEACH  => {
    noun         => 'существительное', # іменник
    adjective    => 'прилагательное',  # прикметник
    numeral      => 'числительное',    # числівник
    pronoun      => 'местоимение',     # займенник
    verb         => 'глагол',          # дієслово
    adverb       => 'наречие',         # прислівник
    preposition  => 'предлог',         # прийменник
    conjunction  => 'союз',            # сполучник
    participle   => 'причастие',       # дієприкметник
    interjection => 'междометие',      # вигук
  },
  # @TODO: implement categories support
  CATEGORIES => {
    auto   => "Автомобильный",
    cable  => "Кабельная промышленность",
  }
};


our $VERSION = '0.01';

sub parse_result {
  my $json = shift;
  my $res;
  my $pos_re = qr[(,\s(?<unknown>\w))?,\s(?<partofspeach>\w+)$]ius;
  if ($json->{isWord} == 1 and $json->{resultNoTags}) {
    my $cur_partofspeach;
    for my $line (split "\r\n" => $json->{resultNoTags}) {
      next if $line =~ /^(\-+|GENERATED_FROM)$/;
      if (0 == index $line => "\n") {
        if ($line =~ $pos_re) {
          # $res->{unknown} = $+{unknown};
          $cur_partofspeach = partofspeach_tr($+{partofspeach});
          $res->{$cur_partofspeach} = [];
        }
      }
      elsif ($line =~ /^\s\-\s(?<word>[\w\/\-\ ]+)
                        (,\s\w)?
                        (\s\((?<word_category>[\w\ ]*)\))?
                        $/iux)
      {
        push @{$res->{$cur_partofspeach}} => [
          $+{word},
          $+{word_category}
        ];
      }
      elsif (not defined $cur_partofspeach) {
        $res->{_} = $line;
      }
    }
  }
  else {
    $res->{_} = $json->{result};
  }
  # p($res);
  $res
}

sub partofspeach_tr($) {
  my $original = shift;
  for my $item (keys %{ +PARTSOFSPEACH }) {
    return $item
      if lc $original eq lc +PARTSOFSPEACH->{$item};
  }
}

sub translate {
  my $class = shift;
  my ($from, $to, $text) = @_;
  # `translate.ru` doesn't support ukrainian :-(
  $from = 'ru' if $from eq 'uk';
  $to   = 'ru' if $to   eq 'uk';
  my $res = $class->SUPER::http_request(
    POST => sprintf(URL, $from, $to, uri_escape_utf8( $text )),

    { 'Accept'           => 'Accept: application/json, text/javascript, */*; q=0.01',
      'Referer'          => 'Referer: http://www.translate.ru/',
      'Content-Type'     => 'application/json; charset=UTF-8',
      'X-Requested-With' => 'XMLHttpRequest',
      'Origin'           => 'http://www.translate.ru' },

       # dirCode should be: er/re/ge/eg/etc.
    {  dirCode           => substr($from,0,1).substr($to,0,1),
       template          => 'Computer', # @TODO: template chould be configurable
       text              => $text,
       lang              => 'ru', # `translate.ru` supports only `ru`?
       limit             => 3000,
       useAutoDetect     => JSON::true,
       key               => '',
       ts                => 'MainSite',
       tid               => '' }
  );
  return if $res->{code} < 0;
  my $json = from_json( $res->{content}, { utf8  => 1 });
  # p($json);
  parse_result($json);
}

1;