package Dict::Learn::Main::Result::Dictionary 0.1;
use base qw[ DBIx::Class::Core ];

__PACKAGE__->table('dictionary');
__PACKAGE__->add_columns(
    qw[ dictionary_id dictionary_name language_orig_id language_tr_id
        note cdate mdate ]
);
__PACKAGE__->set_primary_key('dictionary_id');
__PACKAGE__->has_one(
    language_orig_id => 'Dict::Learn::Main::Result::Language',
    {'foreign.language_id' => 'self.language_orig_id'},
    {   cascade_delete => 0,
        cascade_update => 0
    }
);
__PACKAGE__->has_one(
    language_tr_id => 'Dict::Learn::Main::Result::Language',
    {'foreign.language_id' => 'self.language_tr_id'},
    {   cascade_delete => 0,
        cascade_update => 0
    }
);
__PACKAGE__->has_many(
    words => 'Dict::Learn::Main::Result::Word',
    {'foreign.lang_id' => 'self.language_orig_id'},
    {   cascade_delete => 0,
        cascade_update => 0
    }
);

1;

