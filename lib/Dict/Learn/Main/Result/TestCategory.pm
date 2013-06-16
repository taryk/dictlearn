package Dict::Learn::Main::Result::TestCategory;
use base qw[ DBIx::Class::Core ];
# __PACKAGE__->load_components(qw/InflateColumn::DateTime/);

__PACKAGE__->table('test_category');
__PACKAGE__->add_columns(qw[ test_category_id test_id dictionary_id name cdate mdate ]);
__PACKAGE__->set_primary_key('test_category_id');
__PACKAGE__->has_one(
    lang_id => 'Dict::Learn::Main::Result::Test',
    {'foreign.test_id' => 'self.test_id'},
    {   cascade_delete => 0,
        cascade_update => 0
    }
);
__PACKAGE__->has_one(
    sessions => 'Dict::Learn::Main::Result::Dictionary',
    {'foreign.dictionary_id' => 'self.dictionary_id'},
    {   cascade_delete => 0,
        cascade_update => 0
    }
);

1;
