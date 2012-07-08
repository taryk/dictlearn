package Dict::Learn::Main::Result::Example 0.1;
use base qw[ DBIx::Class::Core ];
__PACKAGE__->table('example');
__PACKAGE__->add_columns(qw[ example_id sentence_orig sentence_tr
                             note cdate mdate ]);
__PACKAGE__->set_primary_key('example_id');
__PACKAGE__->has_many( word_example => 'Dict::Learn::Main::Result::WordExample', 'example_id');
__PACKAGE__->many_to_many( words    => 'word_example', 'word_id');

1;

