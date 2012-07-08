package Dict::Learn::Main::Result::Word 0.1;
use base qw[ DBIx::Class::Core ];
__PACKAGE__->table('word');
__PACKAGE__->add_columns(qw[ word_id word_orig word_tr dictionary_id
                             wordclass_id note cdate mdate ]);
__PACKAGE__->set_primary_key('word_id');
__PACKAGE__->has_one( dictionary    => 'Dict::Learn::Main::Result::Dictionary', 'dictionary_id');
__PACKAGE__->has_one( wordclass     => 'Dict::Learn::Main::Result::Wordclass',
                     { 'foreign.wordclass_id' => 'self.wordclass_id' });
__PACKAGE__->has_many( word_example => 'Dict::Learn::Main::Result::WordExample', 'word_id');
__PACKAGE__->many_to_many( examples => 'word_example', 'example_id');

1;
