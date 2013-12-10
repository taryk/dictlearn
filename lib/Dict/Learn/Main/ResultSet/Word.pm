package Dict::Learn::Main::ResultSet::Word 0.1;
use base 'DBIx::Class::ResultSet';

use Memoize qw[memoize flush_cache];
use Data::Printer;

use namespace::autoclean;
use common::sense;

sub MIN_SCORE { 0.43 }

sub export_data {
    my ($self) = @_;
    my $rs = $self->search({}, {});
    $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
    $rs->all();
}

sub import_data {
    my ($self, $data) = @_;
    $self->populate($data);
    return 1;
}

sub clear_data {
    my ($self) = @_;
    $self->delete_all();
}

sub add_one {
    my ($self, %params) = @_;

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
    for my $word (@{$params{translate}}) {
        my $fields = {};
        if (defined $word->{word_id} and $word->{word_id} >= 0) {
            $fields->{word_id} = $word->{word_id};
        }
        else {
            next unless defined $word->{word};
            $fields = {
                word            => $word->{word},
                partofspeech_id => $word->{partofspeech},
                lang_id         => $word->{lang_id},
            };
        }
        $new_word->add_to_words(
            $fields => {
                dictionary_id   => $params{dictionary_id},
                partofspeech_id => $word->{partofspeech},
                note            => $word->{note},
            }
        );
    }
    $self->get_all_flushcashe;
}

sub update_one {
    my $self     = shift;
    my %params   = @_;
    my %upd_word;
    $upd_word{word}    = $params{word}    if defined $params{word};
    $upd_word{note}    = $params{note}    if defined $params{note};
    $upd_word{lang_id} = $params{lang_id} if defined $params{lang_id};
    $upd_word{in_test} = $params{in_test} if defined $params{in_test};

    if (defined $params{irregular}) {
        if ($upd_word{irregular} = $params{irregular} || 0) {
            $upd_word{word2} = $params{word2};
            $upd_word{word3} = $params{word3};
        }
        else {
            $upd_word{word2} = $upd_word{word3} = undef;
        }
    }
    my $updated_word = $self->search({word_id => $params{word_id}})
        ->first->update(\%upd_word);

    for (@{$params{translate}}) {

        # create new
        unless (defined $_->{word_id}) {
            next unless defined $_->{word};
            $updated_word->add_to_words(
                {
                    word    => $_->{word},
                    lang_id => $_->{lang_id},
                },
                {
                    dictionary_id   => $params{dictionary_id},
                    partofspeech_id => $_->{partofspeech},
                    note            => $_->{note},
                }
            );
            next;
        }

        # update or delete existed
        my $word_xref
            = $self->result_source->schema->resultset('Words')
            ->find_or_create(
                {
                    word1_id => $params{word_id},
                    word2_id => $_->{word_id},
                    # FIXME there is also third primary column - 'rel_type',
                    # but it is not implemented ATM
                }
            );
        if (defined $_->{word}) {
            next if $_->{word} == 0;
            my $first = $word_xref->first;
            $first->update(
                {
                    partofspeech_id => $_->{partofspeech},
                    note            => $_->{note},
                }
            );
            $first->word2_id->update(
                {
                    word    => $_->{word},
                    lang_id => $_->{lang_id},
                }
            );
        }
        else {
            # delete word if `word` is undefined
            $word_xref->delete;
        }
    }

    $self->get_all_flushcashe;

    return $self;
}

sub delete_one {
    my $self = shift;
    $self->search({word_id => [@_]})->delete;
    $self->get_all_flushcashe;
}

sub unlink_one {
    my $self = shift;
    $self->result_source->schema->resultset('Words')
        ->search({word1_id => [@_]})->delete;
}

memoize('find_ones', INSTALL => 'find_ones_cached');

sub find_ones {
    my ($self, %params) = @_;

    my %where;
    if ($params{partofspeech}) {
        $where{'-or'} = [
            'partofspeech.abbr'      => $params{partofspeech},
            'partofspeech.name_orig' => ucfirst($params{partofspeech}),
        ];
    } elsif ($params{filter}) {
        given ($params{filter}) {
            when('translated') {
                $where{'rel_words.word2_id'} = { '!=' => undef };
            }
            when('untranslated') {
                $where{'rel_words.word2_id'} =  undef;
            }
            when('irregular') {
                $where{'me.irregular'} = 1;
            }
        }
    } else {
        for my $word (@{$params{word}}) {
            my $word_pattern = "%${word}%";
            for my $column (qw(me.word me.word2 me.word3 word2_id.word)) {
                push @{ $where{-or} }, ($column => { like => $word_pattern });
            }
        }
    }
    my $rs = $self->search(
        {
            -and => [
                'me.lang_id' => $params{lang_id},
                %where,
            ],
        },
        {
            join   => { 'rel_words' => ['word2_id', 'partofspeech'] },
            select => [
                'me.word_id', 'me.word',
                'me.word2',   'me.word3',

                ## no critic (ValuesAndExpressions::ProhibitInterpolationOfLiterals)
                'me.irregular', { group_concat => ['word2_id.word', "', '"] },

                ## use critic
                'me.mdate', 'me.cdate',
                'me.note',  'partofspeech.abbr',
                'me.in_test'
            ],
            as => [
                qw[
                    word_id word_orig word2 word3 is_irregular word_tr
                    mdate cdate note partofspeech in_test
                  ]
            ],
            group_by => ['me.word_id', 'rel_words.partofspeech_id'],
            order_by => { -asc => 'me.cdate' },
        }
    );

    $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
    say "find_ones uncached";
    my @result = $rs->all();
    if ($params{word} && scalar @{$params{word}} > 0) {
        # Word with a relevance of 100% should go first
        for (@result) {
            next if $_->{word_orig} ne $params{word}[0];
            unshift @result, $_;
            undef $_;
            last;
        }
    }
    return @result;
}

sub find_ones_flushcashe {
    my $self = shift;
    flush_cache('find_ones_cached');
    $self;
}

sub match {
    my ($self, $lang_id, $word) = @_;

    my $rs = $self->search(
        {
            lang_id => $lang_id,

            # FIXME is there a better way to search with 'COLLATE NOCASE'?
            word => \sprintf(' = %s COLLATE NOCASE',
                $self->result_source->schema->storage->dbh->quote($word)),
        }
    );

    say "match uncached";
    return $rs;
}

sub select {
    my ($self, $lang_id, $word) = @_;
    my $params = {'lang_id' => $lang_id};
    $params->{word} = {like => "%$word%"} if $word;
    my $rs = $self->search(
        $params,
        {   distinct => 1,
            select   => [qw| me.word_id me.word partofspeech.abbr |],
            as       => [qw| id word partofspeech |],
            join     => ['partofspeech'],
        }
    );
    $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
    say "select uncached";
    $rs->all();
}

sub select_one {
    my ($self, $word_id) = @_;
    my $rs = $self->search({'me.word_id' => $word_id,},
        {prefetch => {'rel_words' => ['word2_id']}});
    $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
    say "select_one uncached";
    $rs->first();
}

sub select_words_grid {
    my $self   = shift;
    my %params = @_;
    my $rs     = $self->search(
        {'me.lang_id' => $params{lang1_id}},
        {   join   => ['rel_words', 'examples', 'partofspeech'],
            select => [
                'me.word_id',
                'me.word',
                'me.word2',
                'me.word3',
                'me.irregular',
                'partofspeech.abbr',
                'me.in_test',
                {count => ['rel_words.word2_id']},
                {count => ['examples.example_id']},
                'me.cdate',
                'me.mdate'
            ],
            as => [
                qw|word_id word word2 word3 is_irregular partofspeech in_test
                    rel_words rel_examples cdate mdate|
            ],
            group_by => ['me.word_id'],
            order_by => {-desc => ['me.cdate']}
        }
    );
    $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
    say "select_words_grid uncached";
    $rs->all();
}

memoize('get_all', INSTALL => 'get_all_cached');

sub get_all {
    my $self    = shift;
    my $lang_id = shift;
    my $rs      = $self->search({'me.lang_id' => $lang_id,});
    $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
    $rs->all();
}

sub get_all_flushcashe {
    my $self = shift;
    flush_cache('get_all_cached');
    $self;
}

sub get_irregular_verbs {
    my ($self, $min_count) = @_;
    my @res;

    # replace by join
    my @words = $self->result_source->schema->resultset('TestSessionData')
        ->get_words();

    ## no critic (Subroutines::ProhibitNestedSubs)
    sub search_irregular_verbs {
        my $self = shift;
        $self->search(
            {   irregular => 1,
                in_test   => 1,
                %{$_[0]}
            },
            {   select => [qw|me.word_id me.word me.word2 me.word3 |],
                %{$_[1]}
            }
        );
    }
    ## use critic

    # select untested words
    my $rs_untested = $self->search_irregular_verbs(
        {word_id => {-not_in => [map { $_->{word_id} } @words]}});
    $rs_untested->result_class('DBIx::Class::ResultClass::HashRefInflator');
    push @res => $rs_untested->all();

    # select failed words ( scrore <= 0.5 )
    unless (@res >= $min_count) {
        my $rs_failed = $self->search_irregular_verbs(
            {   word_id => {
                    -in => [
                        map  { $_->{word_id} }
                        grep { $_->{avg_score} < MIN_SCORE } @words
                    ]
                }
            }
        );
        $rs_failed->result_class('DBIx::Class::ResultClass::HashRefInflator');
        push @res => $rs_failed->all();
    }

    # select other words ( any scrore )
    # TODO: oldest passed ones at first
    unless (@res >= $min_count) {
        my $limit = $min_count - scalar @res;
        my $rs_other
            = $self->search_irregular_verbs(
            {word_id => {-not_in => [map { $_->{word_id} } @res]}},
            {limit   => $limit});
        $rs_other->result_class('DBIx::Class::ResultClass::HashRefInflator');
        push @res => $rs_other->all();
    }

    @res;
}

1;
