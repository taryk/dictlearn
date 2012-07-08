package Dict::Learn::Main::Result::Language 0.1;
use base qw[ DBIx::Class::Core ];
__PACKAGE__->table('language');
__PACKAGE__->add_columns(qw[ language_id language_name
                             note cdate mdate ]);
__PACKAGE__->set_primary_key('language_id');

1;

