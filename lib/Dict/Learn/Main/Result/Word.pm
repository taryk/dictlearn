package Dict::Learn::Main::Result::Word 0.2;
use base qw[ DBIx::Class::Core ];

__PACKAGE__->table('word');
__PACKAGE__->add_columns(
    qw[ word_id word word2 word3 irregular lang_id partofspeech_id in_test
        note cdate mdate example ]
);
__PACKAGE__->set_primary_key('word_id');
__PACKAGE__->has_one(
    partofspeech => 'Dict::Learn::Main::Result::PartOfSpeech',
    {'foreign.partofspeech_id' => 'self.partofspeech_id'},
    {   cascade_delete => 0,
        cascade_update => 0
    }
);
__PACKAGE__->might_have(
    examples => 'Dict::Learn::Main::Result::WordExample',
    'word_id',
    {   cascade_delete => 0,
        cascade_update => 0
    }
);
__PACKAGE__->has_many(
    rel_words => 'Dict::Learn::Main::Result::Words',
    {"foreign.word1_id" => "self.word_id"},
    {   cascade_delete => 0,
        cascade_update => 0
    }
);
__PACKAGE__->many_to_many(words => 'rel_words', 'word2_id');

__PACKAGE__->might_have(
    last_test => 'Dict::Learn::Main::Result::TestSessionData',
    'word_id',
    #{ group_by => { "fereign" => 1 } }
    #{   cascade_delete => 0,
    #    cascade_update => 0
    #}
);

# __PACKAGE__->has_many( words_tr  => 'Dict::Learn::Main::Result::Words', 'word2_id');

1;
