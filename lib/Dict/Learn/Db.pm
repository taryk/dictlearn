package Dict::Learn::Db 0.1;

use common::sense;

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
  my @examples;
  for my $item (@{ $params{examples} }) {
    push @examples  => {
      sentence_orig => $item->{sentence_orig},
      sentence_tr   => $item->{sentence_tr},
      note          => $item->{note}
    };
  }
  my $new_word = $self->schema->resultset('Word')->create({
    word_orig     => $params{word_orig},
    word_tr       => $params{word_tr},
    dictionary_id => $self->dictionary_id,
    wordclass_id  => $params{wordclass},
    note          => $params{note},
    # examples      => [ @examples ],
  });

  # p($newword);
  for my $item (@{ $params{examples} }) {
    $new_word->add_to_examples( $item );
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
      # p($item);
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
  # $self->schema->populate( 'Example' => [
  #   [qw| sentence_orig sentence_tr |],
  #   [ $params{sentence_orig}, $params{sentence_tr} ],
  # ]);
  # $self->schema->populate( 'WordExample' => [
  #   [qw| word_id example_id |],
  #   [ $params{word_id}, $params{example_id} ],
  # ]);
  # $self->schema->resultset('Example')->create({ ... });
  $self
}

sub update_example { my $self = shift }

sub delete_example { my $self = shift }

sub find_items {
  my $self = shift;
  my $word = shift;
  my $rs   = $self->schema->resultset('Word')->search({
    -and => [
      dictionary_id => $self->dictionary_id,
      -or => [
        word_orig => { like => "%$word%" },
        word_tr   => { like => "%$word%" },
      ],
    ]
  },
  { 'join'    => 'wordclass',
    '+select' => 'wordclass.abbr',
    '+as'     => 'wordclass_abbr' });
  $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
  $rs->all;
}

sub select_all {
  my $self = shift;
  my $rs   = $self->schema->resultset('Word')->search(
    { dictionary_id => $self->dictionary_id },
    { 'join'     => 'wordclass',
      '+select'  => 'wordclass.abbr',
      '+as'      => 'wordclass_abbr',
      'order_by' => { -asc => 'word_orig' } },
  );
  $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
  $rs->all
}

sub select_wordclass {
  my $self = shift;
  my $rs   = $self->schema->resultset('Wordclass')->search({},
    { order_by => { -asc => 'wordclass_id' } });
  $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
  $rs->all
}

sub select_examples {
  my $self    = shift;
  my $word_id = shift;
  my $rs   = $self->schema->resultset('Example')->search(
   { 'word_example.word_id' => $word_id   },
   { 'join'     => 'word_example',
     'order_by' => { -asc => 'me.example_id' }
  });
  $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
  $rs->all
}

1;
