package Dict::Learn::Main::Result::WordExample 0.2;
use base qw[ DBIx::Class::Core ];
__PACKAGE__->table('word_example_xref');
__PACKAGE__->add_columns(
    qw[ word_id example_id wordclass_id
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
    wordclass => 'Dict::Learn::Main::Result::Wordclass',
    {'foreign.wordclass_id' => 'self.wordclass_id'},
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
