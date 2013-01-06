package Dict::Learn::Main::Result::Test 0.1;
use base qw[ DBIx::Class::Core ];
__PACKAGE__->table('test');
__PACKAGE__->add_columns(qw[ test_id name lang_id enable cdate mdate ]);
__PACKAGE__->set_primary_key('test_id');
__PACKAGE__->has_one( lang_id => 'Dict::Learn::Main::Result::Language',
                    { 'foreign.language_id' => 'self.lang_id' },
                    { cascade_delete => 0 ,
                      cascade_update => 0 });
__PACKAGE__->has_many( sessions => 'Dict::Learn::Main::Result::TestSession',
                     { 'foreign.test_id' => 'self.test_id' },
                     { cascade_delete => 0 ,
                       cascade_update => 0 });

1;

