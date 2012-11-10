package Dict::Learn::Db 0.1;

use common::sense;
use namespace::autoclean;

use Data::Printer;

use Class::XSAccessor
    accessors => [ qw| schema
                       dictionary_id | ];

sub new {
  my $class  = shift;
  my $self = bless {} => $class;
  $self->schema( shift );
  $self->dictionary_id( 0 );
  $self
}

sub add_word {
  my $self   = shift;
  my %params = @_;
  my $new_word = $self->schema->resultset('Word')->create({
    word    => $params{word},
    note    => $params{note},
    lang_id => $params{lang_id},
  });
  for my $word ( @{$params{translate}} ) {
    my $fields = { };
    if ($word->{word_id}) {
      $fields->{word_id} = $word->{word_id};
    } else {
      $fields = { word          => $word->{word},
                  wordclass_id  => $word->{wordclass},
                  lang_id       => $word->{lang_id}, }
    }
    $new_word->add_to_words($fields => {
      dictionary_id => $self->dictionary_id
    });
  }
  $self
}

sub update_item {
  my $self   = shift;
  my %params = @_;
  my $examples = delete $params{examples};
  my $updated_word = $self->schema->resultset('Word')->find(
    { word_id => delete($params{word_id}) }
  );
  $updated_word->update({ %params });
  for my $item (@$examples) {
    if ( defined $item->{example_id} and
                 $item->{example_id} > 0 )
    {
      $self->schema->resultset('Example')->search(
        { example_id => $item->{example_id} },
      )->update($item);
    }
    else {
      $updated_word->add_to_examples($item);
    }
  }

}

sub update_word {
  my $self   = shift;
  my %params = @_;
  my $updated_word = $self->schema->resultset('Word')->
  search({ word_id => $params{word_id} })->first->update({
    word    => $params{word},
    note    => $params{note},
    lang_id => $params{lang_id},
  });
  for ( @{ $params{translate} } ) {
    unless (defined $_->{word_id}) {
      $updated_word->add_to_words({
        word    => $_->{word},
        note    => $_->{note},
        lang_id => $_->{lang_id},
      }, {
        dictionary_id => $self->dictionary_id,
        wordclass_id  => $_->{wordclass},
      });
      next;
    }
    my $rs = $self->schema->resultset('Words')->search({
      word1_id => $params{word_id},
      word2_id => $_->{word_id},
    });
    if ($_->{word}) {
      $rs->first->update({ wordclass_id => $_->{wordclass} })->word2_id->update({
        word    => $_->{word},
        note    => $_->{note},
        lang_id => $_->{lang_id},
      });
    } else {
      $rs->delete;
    }
  }
}

sub delete_word {
  my $self = shift;
  $self->schema->resultset('Word')->search({ word_id => [ @_ ] })->delete;
}

sub add_example {
  my $self   = shift;
  my %params = @_;
  my $new_example = $self->schema->resultset('Example')->create({
    example => $params{text},
    note    => $params{note},
    lang_id => $params{lang_id},
  });
  if ($params{word}) {
    my $rs = $self->schema->resultset('WordExample')->create({
      word_id    => $params{word}[0],
      example_id => $new_example->example_id,
    });
  }
  for (@{ $params{translate} }) {
    $new_example->add_to_examples({
      example => $_->{text},
      lang_id => $_->{lang_id},
    }, {
      dictionary_id => $self->dictionary_id
    });
  }
}

sub update_example {
  my $self = shift;
  my %params = @_;
  my $updated_example = $self->schema->resultset('Example')->
  search({ example_id => $params{example_id} })->first->update({
    example => $params{text},
    note    => $params{note},
    lang_id => $params{lang_id},
    idioma  => $params{idioma} || 0,
  });
  for ( @{ $params{translate} } ) {
    unless (defined $_->{example_id}) {
      $updated_example->add_to_examples({
        example => $_->{text},
        note    => $_->{note},
        lang_id => $_->{lang_id},
        idioma  => $_->{idioma} || 0,
      }, {
        dictionary_id => $self->dictionary_id,
      });
      next;
    }
    my $rs = $self->schema->resultset('Examples')->search({
      example1_id => $params{example_id},
      example2_id => $_->{example_id},
    });
    if ($_->{text}) {
      $rs->first->example2_id->update({
        example => $_->{text},
        note    => $_->{note},
        lang_id => $_->{lang_id},
        idioma  => $_->{idioma} || 0,
      });
    } else {
      $rs->delete;
    }
  }
}

sub delete_example { my $self = shift }

sub find_items {
  my $self = shift;
  my $word = shift;
  my $rs   = $self->schema->resultset('Words')->search({
    -and => [
      'me.dictionary_id' => $self->dictionary_id,
      'word1_id.word'    => { like => "%$word%" },
    ]}, {
      join     => [ qw| word1_id word2_id wordclass | ],
      select   => [ 'me.word1_id', 'word1_id.word', { group_concat => [ 'word2_id.word', "', '" ] }, 'me.mdate', 'me.cdate', 'me.note', 'wordclass.abbr' ],
      as       => [ qw| word_id word_orig word_tr mdate cdate note wordclass | ],
      group_by => [ 'me.word1_id', 'me.wordclass_id' ],
    }
  );
  $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
  my @r1 = $rs->all;
  # p(@r1);
  @r1
}

sub select_words {
  my ($self, $lang_id, $word) = @_;
  my $params = { 'lang_id' => $lang_id };
  $params->{word} = { like => "%$word%" } if $word;
  my $rs      = $self->schema->resultset('Word')->search( $params, {
    distinct => 1,
    select   => [ qw| me.word_id me.word wordclass.abbr | ],
    as       => [ qw| id word wordclass | ],
    join     => [ 'wordclass' ],
  });
  $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
  $rs->all;
}

sub select_word {
  my $self    = shift;
  my $word_id = shift;
  my $rs = $self->schema->resultset('Word')->search({
      'me.word_id'  => $word_id,
    },{
      prefetch => { 'rel_words' => [ 'word2_id' ] },
    }
  );
  $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
  $rs->first;
}

# @TODO get related words
sub select_example {
  my $self       = shift;
  my $example_id = shift;
  my $rs = $self->schema->resultset('Example')->search({
      'me.example_id'  => $example_id,
    },{
      prefetch => { 'rel_examples' => [ 'example2_id' ] },
    }
  );
  $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
  $rs->first;
}

sub select_all {
  my $self = shift;
  my $rs   = $self->schema->resultset('Words')->search(
    { 'me.dictionary_id' => $self->dictionary_id },
    { prefetch => [ qw| word1_id word2_id wordclass | ] }
  );
  $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
  my @r1 = $rs->all;
  # p(@r1);
  @r1
}

sub select_wordclass {
  my $self = shift;
  my %params = @_;
  my $args = {};
  if ($params{name}) {
    $args->{-or} = [
      name_orig => { -like => $params{name} },
      name_tr   => { -like => $params{name} },
    ];
  }
  my $rs = $self->schema->resultset('Wordclass')->search($args,
    { order_by => { -asc => 'wordclass_id' } });
  $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
  $rs->all
}

sub select_examples {
  my $self    = shift;
  my $word_id = shift;
  my $rs   = $self->schema->resultset('WordExample')->search({
    -and => [
       'me.word_id' => $word_id,
       'rel_examples.dictionary_id' => $self->dictionary_id,
    ],
  }, {
    select => [ qw| rel_examples.note
                    example1_id.example_id
                    example1_id.example
                    example1_id.note
                    example2_id.example_id
                    example2_id.example
                    example2_id.note
                  | ],
     join   => { rel_examples => ['example1_id', 'example2_id'] },
     # order_by => { -asc => 'me.example_id' }
  });
  $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
  $rs->all
}

sub get_dictionary {
  my $self = shift;
  my $dictionary_id = shift;
  my $rs = $self->schema->resultset('Dictionary')->search({
    dictionary_id => $dictionary_id
  }, {
    prefetch => [ qw| language_orig_id language_tr_id | ],
  });
  $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
  $rs->all
}

1;

