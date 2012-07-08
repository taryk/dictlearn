package Dict::Learn::Main::Result::WordExample 0.1;
use base qw[ DBIx::Class::Core ];
__PACKAGE__->table('word_example_xref');
__PACKAGE__->add_columns(qw[ word_id example_id
                             note cdate mdate ]);
__PACKAGE__->set_primary_key(qw[ word_id example_id ]);
__PACKAGE__->belongs_to( word_id    => 'Dict::Learn::Main::Result::Word', 'word_id' );
__PACKAGE__->belongs_to( example_id => 'Dict::Learn::Main::Result::Example', 'example_id' );

1;

