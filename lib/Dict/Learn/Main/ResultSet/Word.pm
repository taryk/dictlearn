package Dict::Learn::Main::ResultSet::Word 0.1;
use base 'DBIx::Class::ResultSet';

use namespace::autoclean;

use common::sense;

use Data::Printer;

use constant {
  MIN_SCORE => 0.43,
};

sub export_data {
  my ($self) = @_;
  my $rs = $self->search({ }, { });
  $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
  $rs->all()
}

sub import_data {
  my ($self, $data) = @_;
  $self->populate($data);
  return 1
}

sub clear_data {
  my ($self) = @_;
  $self->delete_all()
}

sub add_one {
  my $self   = shift;
  my %params = @_;
  my %new_word = (
    word    => $params{word},
    note    => $params{note},
    lang_id => $params{lang_id},
  );
  $new_word{in_test} = $params{in_test} if defined $params{in_test};
  if ($new_word{irregular} = $params{irregular}) {
    $new_word{word2} = $params{word2};
    $new_word{word3} = $params{word3};
  }
  my $new_word = $self->create(\%new_word);
  for my $word ( @{$params{translate}} ) {
    my $fields = { };
    if (defined $word->{word_id} and $word->{word_id} >= 0) {
      $fields->{word_id} = $word->{word_id};
    } else {
      next unless defined $word->{word};
      $fields = { word          => $word->{word},
                  wordclass_id  => $word->{wordclass},
                  lang_id       => $word->{lang_id}, }
    }
    $new_word->add_to_words($fields => {
      dictionary_id => $params{dictionary_id},
      wordclass_id  => $word->{wordclass},
    });
  }
  $self
}

sub update_one {
  my $self   = shift;
  my %params = @_;
  my %upd_word = ( );
  $upd_word{word}    = $params{word}    if defined $params{word};
  $upd_word{note}    = $params{note}    if defined $params{note};
  $upd_word{lang_id} = $params{lang_id} if defined $params{lang_id};
  $upd_word{in_test} = $params{in_test} if defined $params{in_test};

  if (defined $params{irregular}) {
    if ($upd_word{irregular} = $params{irregular} || 0) {
      $upd_word{word2} = $params{word2};
      $upd_word{word3} = $params{word3};
    } else {
      $upd_word{word2} = $upd_word{word3} = undef;
    }
  }
  my $updated_word = $self->search({ word_id => $params{word_id} })->
    first->update(\%upd_word);
  for ( @{ $params{translate} } ) {
    # create new
    unless (defined $_->{word_id}) {
      next unless defined $_->{word};
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
    my $word_xref = $self->result_source->schema->resultset('Words')->find_or_create({
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
      # delete word if `word` is undefined
      $word_xref->delete;
    }
  }
  $self
}

sub delete_one {
  my $self = shift;
  $self->search(
    { word_id => [ @_ ] }
  )->delete
}

sub unlink_one {
  my $self = shift;
  $self->result_source->schema->resultset('Words')->search(
    { word1_id => [ @_ ] }
  )->delete
}

sub find_ones {
  my $self   = shift;
  my %params = @_;
  my $word_pattern = "%".$params{word}."%";
  my $rs = $self->search({
    -and => [
      'me.lang_id' => $params{lang_id},
      -or => [
        'me.word'  => { like => $word_pattern },
        'me.word2' => { like => $word_pattern },
        'me.word3' => { like => $word_pattern },
      ]
    ]}, {
      join     => { 'rel_words' => [ 'word2_id', 'wordclass' ] },
      select   => [ 'me.word_id', 'me.word', 'me.word2', 'me.word3', 'me.irregular',
                  { group_concat => [ 'word2_id.word', "', '" ] },
                    'me.mdate', 'me.cdate', 'me.note', 'wordclass.abbr', 'me.in_test' ],
      as       => [ qw| word_id word_orig word2 word3 is_irregular word_tr
                        mdate cdate note wordclass in_test
                      | ],
      group_by => [ 'me.word_id', 'rel_words.wordclass_id' ],
      order_by => { -asc => 'me.cdate' },
    }
  );
  $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
  $rs->all()
}

sub match {
  my ($self, $lang_id, $word) = @_;
  my $rs = $self->search({
    lang_id => $lang_id,
    word    => $word,
  });
  $rs
}

sub select {
  my ($self, $lang_id, $word) = @_;
  my $params = { 'lang_id' => $lang_id };
  $params->{word} = { like => "%$word%" } if $word;
  my $rs      = $self->search( $params, {
    distinct => 1,
    select   => [ qw| me.word_id me.word wordclass.abbr | ],
    as       => [ qw| id word wordclass | ],
    join     => [ 'wordclass' ],
  });
  $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
  $rs->all()
}

sub select_one {
  my ($self, $word_id) = @_;
  my $rs = $self->search({
      'me.word_id'  => $word_id,
    },{
      prefetch => { 'rel_words' => [ 'word2_id' ] },
    }
  );
  $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
  $rs->first()
}

sub select_words_grid {
  my $self   = shift;
  my %params = @_;
  my $rs   = $self->search(
    { 'me.lang_id' => $params{lang1_id} },
    { join     => [ 'rel_words', 'examples', 'wordclass' ],
      select   => [ 'me.word_id', 'me.word', 'me.word2', 'me.word3',
                    'me.irregular', 'wordclass.abbr', 'me.in_test',
                  { count => [ 'rel_words.word2_id'  ] },
                  { count => [ 'examples.example_id' ] },
                    'me.cdate', 'me.mdate' ],
      as       => [ qw|word_id word word2 word3 is_irregular wordclass in_test
                       rel_words rel_examples cdate mdate| ],
      group_by => [ 'me.word_id' ],
      order_by => { -desc => [ 'me.cdate' ] }
    }
  );
  $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
  $rs->all()
}

sub get_all {
  my $self = shift;
  my $lang_id = shift;
  my $rs = $self->search({
     'me.lang_id' => $lang_id,
  });
  $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
  $rs->all()
}

sub get_irregular_verbs {
  my ($self, $min_count) = @_;
  my @res;
  # replace by join
  my @words = $self->result_source->schema->resultset('TestSessionData')->get_words();

  sub search_irregular_verbs {
    my $self = shift;
    $self->search({
        irregular => 1,
        in_test   => 1,
        %{$_[0]}
      }, {
        select => [ qw|me.word_id me.word me.word2 me.word3 | ],
        %{$_[1]}
    })
  }

  # select untested words
  my $rs_untested = $self->search_irregular_verbs({
    word_id => { -not_in => [ map { $_->{word_id} } @words ] }
  });
  $rs_untested->result_class('DBIx::Class::ResultClass::HashRefInflator');
  push @res => $rs_untested->all();

  # select failed words ( scrore <= 0.5 )
  unless (@res >= $min_count) {
    my $rs_failed = $self->search_irregular_verbs({
      word_id => { -in => [ map { $_->{word_id} } grep { $_->{avg_score} < MIN_SCORE } @words ] }
    });
    $rs_failed->result_class('DBIx::Class::ResultClass::HashRefInflator');
    push @res => $rs_failed->all();
  }

  # select other words ( any scrore )
  # TODO: oldest passed ones at first
  unless (@res >= $min_count) {
    my $limit = $min_count - scalar @res;
    my $rs_other = $self->search_irregular_verbs(
      { word_id => { -not_in => [ map { $_->{word_id} } @res ] } },
      { limit   => $limit }
    );
    $rs_other->result_class('DBIx::Class::ResultClass::HashRefInflator');
    push @res => $rs_other->all();
  }

  @res
}

1;
