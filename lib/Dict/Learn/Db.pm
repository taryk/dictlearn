package Dict::Learn::Db 0.1;

use common::sense;
use namespace::autoclean;

use Data::Printer;

use Class::XSAccessor
    accessors => [ qw| schema | ];

sub new {
  my $class  = shift;
  my $self = bless {} => $class;
  $self->schema( shift );
  $self
}

sub add_word {
  my $self   = shift;
  my %params = @_;
  my %new_word = (
    word    => $params{word},
    note    => $params{note},
    lang_id => $params{lang_id},
  );
  if ($new_word{irregular} = $params{irregular}) {
    $new_word{word2} = $params{word2};
    $new_word{word3} = $params{word3};
  }
  my $new_word = $self->schema->resultset('Word')->create(\%new_word);
  for my $word ( @{$params{translate}} ) {
    my $fields = { };
    if (defined $word->{word_id} and $word->{word_id} >= 0) {
      $fields->{word_id} = $word->{word_id};
    } else {
      $fields = { word          => $word->{word},
                  wordclass_id  => $word->{wordclass},
                  lang_id       => $word->{lang_id}, }
    }
    $new_word->add_to_words($fields => {
      dictionary_id => $params{dictionary_id},
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
  my %upd_word = (
    word    => $params{word},
    note    => $params{note},
    lang_id => $params{lang_id},
  );
  if ($upd_word{irregular} = $params{irregular}) {
    $upd_word{word2} = $params{word2};
    $upd_word{word3} = $params{word3};
  } else {
    $upd_word{word2} = $upd_word{word3} = undef;
  }
  my $updated_word = $self->schema->resultset('Word')->
    search({ word_id => $params{word_id} })->first->update(\%upd_word);
  for ( @{ $params{translate} } ) {
    # create new
    unless (defined $_->{word_id}) {
      $updated_word->add_to_words({
        word    => $_->{word},
        note    => $_->{note},
        lang_id => $_->{lang_id},
      }, {
        dictionary_id => $params{dictionary_id},
        wordclass_id  => $_->{wordclass},
      });
      next;
    }
    # update or delete existed
    my $word_xref = $self->schema->resultset('Words')->find_or_create({
      word1_id => $params{word_id},
      word2_id => $_->{word_id},
    });
    if (defined $_->{word}) {
      next if $_->{word} == 0;
      $word_xref->first->update({ wordclass_id => $_->{wordclass} })->word2_id->update({
        word    => $_->{word},
        note    => $_->{note},
        lang_id => $_->{lang_id},
      });
    } else {
      $word_xref->delete;
    }
  }
}

sub delete_word {
  my $self = shift;
  $self->schema->resultset('Word')->search(
    { word_id => [ @_ ] }
  )->delete;
}

sub unlink_word {
  my $self = shift;
  $self->schema->resultset('Words')->search(
    { word1_id => [ @_ ] }
  )->delete;
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
    if (defined $_->{example_id}) {
      $new_example->add_to_examples(
        { example_id    => $_->{example_id}     } ,
        { dictionary_id => $params{dictionary_id} }
      );
    } else {
      $new_example->add_to_examples({
        example => $_->{text},
        lang_id => $_->{lang_id},
      }, {
        dictionary_id => $params{dictionary_id}
      });
    }
  }
}

sub update_example {
  my $self = shift;
  my %params = @_;
  my %update = ( example => $params{text} );
  $update{note}    = $params{note}    if defined $params{note};
  $update{lang_id} = $params{lang_id} if defined $params{lang_id};
  $update{idioma}  = $params{idioma}  if defined $params{idioma};
  my $updated_example = $self->schema->resultset('Example')->
    search({ example_id => $params{example_id} })->first->update(\%update);
  for ( @{ $params{translate} } ) {
    # create new
    unless (defined $_->{example_id}) {
      my %update_tr = ( example => $_->{text} );
      $update_tr{note}    = $_->{note}    if defined $_->{note};
      $update_tr{lang_id} = $_->{lang_id} if defined $_->{lang_id};
      $update_tr{idioma}  = $_->{idioma}  if defined $_->{idioma};
      $updated_example->add_to_examples(\%update_tr, {
        dictionary_id => $params{dictionary_id},
      });
      next;
    }
    # update or delete existed
    my $example_xref = $self->schema->resultset('Examples')->find_or_create({
      example1_id => $params{example_id},
      example2_id => $_->{example_id},
    });
    if (defined $_->{text}) {
      next if $_->{text} == 0;
      $example_xref->example2_id->update({
        example => $_->{text},
        note    => $_->{note},
        lang_id => $_->{lang_id},
        idioma  => $_->{idioma} || 0,
      });
    } else {
      $example_xref->delete;
    }
  }
}

sub delete_example {
  my $self = shift;
  $self->schema->resultset('Example')->search(
    { example_id => [ @_ ] }
  )->delete;
}

sub unlink_example {
  my $self = shift;
  $self->schema->resultset('Examples')->search(
    { example1_id => [ @_ ] }
  )->delete;
}

sub find_items {
  my $self   = shift;
  my %params = @_;
  my $rs   = $self->schema->resultset('Word')->search({
    -and => [
      'me.lang_id' => $params{lang_id},
      'me.word'  => { like => "%".$params{word}."%" },
    ]}, {
      join     => { 'rel_words' => [ 'word2_id', 'wordclass' ] },
      select   => [ 'me.word_id', 'me.word', 'me.word2', 'me.word3', 'me.irregular',
                  { group_concat => [ 'word2_id.word', "', '" ] },
                    'me.mdate', 'me.cdate', 'me.note', 'wordclass.abbr' ],
      as       => [ qw| word_id word_orig word2 word3 is_irregular word_tr
                        mdate cdate note wordclass
                      | ],
      group_by => [ 'me.word_id', 'rel_words.wordclass_id' ],
      order_by => { -asc => 'me.cdate' },
    }
  );
  $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
  my @r1 = $rs->all;
  # p(@r1);
  @r1
}

sub match_word {
  my ($self, $lang_id, $word) = @_;
  my $rs      = $self->schema->resultset('Word')->search({
    lang_id => $lang_id,
    word    => $word,
  });
  $rs
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

sub select_words_grid {
  my $self   = shift;
  my %params = @_;
  my $rs   = $self->schema->resultset('Word')->search(
    { 'me.lang_id' => $params{lang1_id} },
    { join     => [ 'rel_words', 'examples', 'wordclass' ],
      select   => [ 'me.word_id', 'me.word', 'wordclass.abbr',
                  { count => [ 'rel_words.word2_id'  ] },
                  { count => [ 'examples.example_id' ] },
                    'me.cdate', 'me.mdate' ],
      as       => [ qw|word_id word wordclass rel_words rel_examples
                       cdate mdate| ],
      group_by => [ 'me.word_id' ],
      order_by => { -desc => [ 'me.cdate' ] }
    }
  );
  $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
  my @r1 = $rs->all;
  # p(@r1);
  @r1
}

sub select_examples_grid {
  my $self   = shift;
  my %params = @_;
  my $rs   = $self->schema->resultset('Example')->search(
    { 'me.lang_id' => $params{lang1_id} },
    { join     => [ 'rel_examples', 'words' ],
      select   => [ 'me.example_id', 'me.example',
                  { count => [ 'rel_examples.example2_id' ] },
                  { count => [ 'words.word_id' ] },
                    'me.cdate', 'me.mdate' ],
      as       => [ qw|example_id example rel_examples rel_words
                       cdate mdate| ],
      group_by => [ 'me.example_id' ],
      order_by => { -desc => ['me.cdate'] }
    }
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
  my %params  = @_;
  my $rs   = $self->schema->resultset('Example')->search({
    -and => [
       'word_id.word_id' => $params{word_id},
       -or => [
         'rel_examples.dictionary_id' => $params{dictionary_id},
         'rel_examples.dictionary_id' => undef
       ],
    ],
  }, {
    select => [ qw| me.example_id
                    me.example
                    example2_id.example
                    rel_examples.note
                    me.cdate
                    me.mdate
                  | ],
    as     => [ qw| example_id
                    example_orig
                    example_tr
                    note
                    cdate
                    mdate
                  | ],
    join => { rel_examples => [ 'example2_id' ], words => [ 'word_id' ] },
    order_by => { -asc => 'me.example_id' }
  });
  $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
  my @a = $rs->all;
  p(@a);
  @a
}

sub get_all_examples {
  my $self = shift;
  my $lang_id = shift;
  my $rs = $self->schema->resultset('Example')->search({
     'me.lang_id' => $lang_id,
  });
  $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
  $rs->all
}

sub get_all_words {
  my $self = shift;
  my $lang_id = shift;
  my $rs = $self->schema->resultset('Word')->search({
     'me.lang_id' => $lang_id,
  });
  $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
  $rs->all
}

sub get_dictionaries {
  my $self = shift;
  my $params;
  if (defined(my $dictionary_id = shift)) {
    $params = { dictionary_id => $dictionary_id };
  }
  my $rs = $self->schema->resultset('Dictionary')->search($params => {
    prefetch => [ qw| language_orig_id language_tr_id | ],
  });
  $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
  $rs->all
}

sub get_irregular_verbs {
  my ($self) = @_;
  my $rs = $self->schema->resultset('Word')->search(
    { 'me.irregular' => 1 },
    { select => [ qw|me.word me.word2 me.word3 | ] }
  );
  $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
  my @a = $rs->all;
  @a
}

sub select_all_words {
  my ($self) = @_;
  my $rs = $self->schema->resultset('Word')->search({ },{ });
  $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
  [ $rs->all ]
}

sub select_all_words_xref {
  my ($self) = @_;
  my $rs = $self->schema->resultset('Words')->search({ },{ });
  $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
  [ $rs->all ]
}

sub select_all_examples {
  my ($self) = @_;
  my $rs = $self->schema->resultset('Example')->search({ },{ });
  $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
  [ $rs->all ]
}

sub select_all_examples_xref {
  my ($self) = @_;
  my $rs = $self->schema->resultset('Examples')->search({ },{ });
  $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
  [ $rs->all ]
}

sub select_all_words_examples_xref {
  my ($self) = @_;
  my $rs = $self->schema->resultset('WordExample')->search({ },{ });
  $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
  [ $rs->all ]
}

sub import_words {
  my ($self, $data) = @_;
  for my $item (@$data) {
    $self->schema->resultset('Word')->create($item);
  }
  return 1;
}

sub import_words_xref {
  my ($self, $data) = @_;
  for my $item (@$data) {
    $self->schema->resultset('Words')->create($item);
  }
  return 1;
}

sub import_examples {
  my ($self, $data) = @_;
  for my $item (@$data) {
    $self->schema->resultset('Example')->create($item);
  }
  return 1;
}

sub import_examples_xref {
  my ($self, $data) = @_;
  for my $item (@$data) {
    $self->schema->resultset('Examples')->create($item);
  }
  return 1;
}

sub import_words_examples_xref {
  my ($self, $data) = @_;
  for my $item (@$data) {
    $self->schema->resultset('WordExample')->create($item);
  }
  return 1;
}

1;

