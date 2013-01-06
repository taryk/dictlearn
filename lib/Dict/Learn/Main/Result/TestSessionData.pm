package Dict::Learn::Main::Result::TestSessionData 0.1;
use base qw[ DBIx::Class::Core ];
__PACKAGE__->table('test_session_data');
__PACKAGE__->add_columns(qw[ test_session_data_id test_session_id word_id data score
                             cdate mdate ]);
__PACKAGE__->set_primary_key(qw[ test_session_data_id ]);
__PACKAGE__->belongs_to( test_session_id => 'Dict::Learn::Main::Result::TestSession',
                         'test_session_id',
                       { cascade_delete => 0 ,
                         cascade_update => 0 });
__PACKAGE__->belongs_to( word_id => 'Dict::Learn::Main::Result::Word', 'word_id',
                       { cascade_delete => 0 ,
                         cascade_update => 0 });

1;
