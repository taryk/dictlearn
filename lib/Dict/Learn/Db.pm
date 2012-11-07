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
  # $self->schema->populate( 'Word' => [
  #   [qw| word_orig word_tr dictionary_id |],
  #   [ $params{word_orig}, $params{word_tr}, $self->dictionary_id ],
  # ]);
  my $new_word = $self->schema->resultset('Word')->create({
    word    => $params{word},
    note    => $params{note},
    lang_id => $params{lang_id},
  });
  for my $word ( @{$params{translate}} ) {
    $new_word->add_to_words({
      word          => $word->{word},
      wordclass_id  => $word->{wordclass},
      lang_id       => $word->{lang_id},
    }, {
      dictionary_id => $self->dictionary_id
    });
  }

  # for my $item (@{ $params{examples} }) {
  #   my $new_example = $self->schema->resultset('Word')->create({
  #     example => $item->{sentence_orig},
  #     note    => $item->{note},
  #   });
  #   $new_word->add_to_examples( { example_id => $new_example->example_id } );
  #   $new_example->add_to_examples({ example => $item->{sentence_tr} })
  #     if $item->{sentence_tr};
  # }
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

  #
  # Recursive update is not supported over relationships of type 'multi' (word_example)
  #
  # my $res = $self->schema->resultset('Word')->search(
  #  { 'me.word_id' => delete($params{word_id}) },
  #  { join     => [ qw/word_example/ ],
  #    prefetch => [ qw/word_example/ ] }
  # )->update({ %params });
}

sub update_word {
  my $self   = shift;
  my %params = @_;
  $self->schema->resultset('Word')->search({
    word_id => delete($params{id}),
  })->update_all({ %params });
}

sub delete_word {
  my $self = shift;
  $self->schema->resultset('Word')->search({ word_id => [ @_ ] })->delete;
}

sub add_example {
  my $self   = shift;
  my %params = @_;
  # $self->schema->populate( 'Example' => [
  #   [qw| sentence_orig sentence_tr |],
  #   [ $params{sentence_orig}, $params{sentence_tr} ],
  # ]);
  # $self->schema->populate( 'WordExample' => [
  #   [qw| word_id example_id |],
  #   [ $params{word_id}, $params{example_id} ],
  # ]);
  # $self->schema->resultset('Example')->create({ ... });
  # p(%params);
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

sub update_example { my $self = shift }

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
      select   => [ 'me.word1_id', 'word1_id.word', { group_concat => 'word2_id.word' }, 'me.mdate', 'me.cdate', 'me.note', 'wordclass.name_orig' ],
      as       => [ qw| word_id word_orig word_tr mdate cdate note wordclass | ],
      group_by => [ 'word1_id' ],
    }
  );
  $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
  my @r1 = $rs->all;
  # p(@r1);
  @r1
}

sub select_words {
  my $self    = shift;
  my $lang_id = shift;
  my $rs      = $self->schema->resultset('Word')->search({
    'lang_id' => $lang_id,
  }, {
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

# sub select_words {
#   my $self    = shift;
#   my $lang_id = shift;
#   my $rs      = $self->schema->resultset('Words')->search({
#     'me.dictionary_id' => $self->dictionary_id,
#   }, {
#     distinct => 1,
#     select   => [ qw| words.word_id words.word words.wordclass_id | ],
#     as       => [ qw| id word wordclass_id | ],
#     join     => { dictionary => 'words' },
#   });
#   $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
#   my @r1 = $rs->all;
#   p(@r1);
#   @r1
# }

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




