package Dict::Learn::Main::Result::Example 0.2;
use base qw[ DBIx::Class::Core ];
__PACKAGE__->table('example');
__PACKAGE__->add_columns(qw[ example_id example lang_id idioma in_test
                             note cdate mdate ]);
__PACKAGE__->set_primary_key('example_id');
__PACKAGE__->has_many( words => 'Dict::Learn::Main::Result::WordExample', 'example_id',
                     { cascade_delete => 0 ,
                       cascade_update => 0 });
__PACKAGE__->has_many( rel_examples => 'Dict::Learn::Main::Result::Examples',
                     { "foreign.example1_id" => "self.example_id" },
                     { cascade_delete => 0 ,
                       cascade_update => 0 });
__PACKAGE__->many_to_many( examples => 'rel_examples', 'example2_id' );

1;
