package Dict::Learn::Main::Result::Examples 0.2;
use base qw[ DBIx::Class::Core ];
__PACKAGE__->table('example_xref');
__PACKAGE__->add_columns(
    qw[ example1_id example2_id dictionary_id
        note cdate mdate ]
);
__PACKAGE__->set_primary_key(qw[ example1_id example2_id ]);
__PACKAGE__->belongs_to(
    example1_id => 'Dict::Learn::Main::Result::Example',
    {'foreign.example_id' => 'self.example1_id'},
    {   cascade_delete => 0,
        cascade_update => 0
    }
);
__PACKAGE__->belongs_to(
    example2_id => 'Dict::Learn::Main::Result::Example',
    {'foreign.example_id' => 'self.example2_id'},
    {   cascade_delete => 0,
        cascade_update => 0
    }
);
__PACKAGE__->has_many(
    rel_words => 'Dict::Learn::Main::Result::WordExample',
    {'foreign.example_id' => 'self.example1_id'},
    {   cascade_delete => 0,
        cascade_update => 0
    }
);
__PACKAGE__->has_one(
    dictionary => 'Dict::Learn::Main::Result::Dictionary',
    {'foreign.dictionary_id' => 'self.dictionary_id'},
    {   cascade_delete => 0,
        cascade_update => 0
    }
);
1;
