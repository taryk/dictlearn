package Dict::Learn::Main::Result::PartOfSpeech 0.1;
use base qw[ DBIx::Class::Core ];

__PACKAGE__->table('partofspeech');
__PACKAGE__->add_columns(
    qw[ partofspeech_id name_orig name_tr abbr
        note cdate mdate ]
);
__PACKAGE__->set_primary_key('partofspeech_id');

# __PACKAGE__->belongs_to('word');

1;
