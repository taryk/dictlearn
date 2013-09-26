package Dict::Learn::Main::Result::WordExample 0.2;
use base qw[ DBIx::Class::Core ];

__PACKAGE__->table('word_example_xref');
__PACKAGE__->add_columns(
    qw[ word_id example_id partofspeech_id
        note cdate mdate ]
);
__PACKAGE__->set_primary_key(qw[ word_id example_id ]);
__PACKAGE__->belongs_to(
    word_id => 'Dict::Learn::Main::Result::Word',
    'word_id', {cascade_delete => 0}
);
__PACKAGE__->belongs_to(
    example_id => 'Dict::Learn::Main::Result::Example',
    'example_id', {cascade_delete => 0}
);
__PACKAGE__->has_one(
    partofspeech => 'Dict::Learn::Main::Result::PartOfSpeech',
    {'foreign.partofspeech_id' => 'self.partofspeech_id'},
    {   cascade_delete => 0,
        cascade_update => 0
    }
);
__PACKAGE__->has_many(
    rel_examples => 'Dict::Learn::Main::Result::Examples',
    {'foreign.example1_id' => 'self.example_id'},
    {   cascade_delete => 0,
        cascade_update => 0
    }
);

1;
