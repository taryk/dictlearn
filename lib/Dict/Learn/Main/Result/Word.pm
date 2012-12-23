package Dict::Learn::Main::Result::Word 0.2;
use base qw[ DBIx::Class::Core ];
__PACKAGE__->table('word');
__PACKAGE__->add_columns(qw[ word_id word word2 word3 irregular lang_id wordclass_id
                             note cdate mdate ]);
__PACKAGE__->set_primary_key('word_id');
__PACKAGE__->has_one( wordclass     => 'Dict::Learn::Main::Result::Wordclass',
                    { 'foreign.wordclass_id' => 'self.wordclass_id' },
                    { cascade_delete => 0 ,
                      cascade_update => 0 });
__PACKAGE__->might_have( examples => 'Dict::Learn::Main::Result::WordExample', 'word_id',
                       { cascade_delete => 0 ,
                         cascade_update => 0 });
__PACKAGE__->has_many( rel_words => 'Dict::Learn::Main::Result::Words',
                      { "foreign.word1_id" => "self.word_id" },
                      { cascade_delete => 0 ,
                        cascade_update => 0 });
__PACKAGE__->many_to_many( words => 'rel_words', 'word2_id');

# __PACKAGE__->has_many( words_tr  => 'Dict::Learn::Main::Result::Words', 'word2_id');

1;
