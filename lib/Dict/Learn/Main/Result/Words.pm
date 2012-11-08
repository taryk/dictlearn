package Dict::Learn::Main::Result::Words 0.2;
use base qw[ DBIx::Class::Core ];
__PACKAGE__->table('word_xref');
__PACKAGE__->add_columns(qw[ word1_id word2_id dictionary_id wordclass_id category_id
                             note cdate mdate ]);
__PACKAGE__->set_primary_key(qw[ word1_id word2_id ]);
__PACKAGE__->has_one( dictionary => 'Dict::Learn::Main::Result::Dictionary',
                    { 'foreign.dictionary_id' => 'self.dictionary_id' },
                    { cascade_update => 0 ,
                      cascade_delete => 0 });
__PACKAGE__->belongs_to( word1_id => 'Dict::Learn::Main::Result::Word',
                       { 'foreign.word_id' => 'self.word1_id' },
                       { cascade_delete => 0 ,
                         cascade_update => 0 });
__PACKAGE__->belongs_to( word2_id => 'Dict::Learn::Main::Result::Word',
                       { 'foreign.word_id' => 'self.word2_id' },
                       { cascade_delete => 0 ,
                         cascade_update => 0 });
__PACKAGE__->has_one( wordclass     => 'Dict::Learn::Main::Result::Wordclass',
                    { 'foreign.wordclass_id' => 'self.wordclass_id' },
                    { cascade_delete => 0 ,
                      cascade_update => 0 });

1;
