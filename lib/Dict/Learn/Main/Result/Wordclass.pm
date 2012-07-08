package Dict::Learn::Main::Result::Wordclass 0.1;
use base qw[ DBIx::Class::Core ];
__PACKAGE__->table('wordclass');
__PACKAGE__->add_columns(qw[ wordclass_id name_orig name_tr abbr
                             note cdate mdate ]);
__PACKAGE__->set_primary_key('wordclass_id');
# __PACKAGE__->belongs_to('word');
1;
