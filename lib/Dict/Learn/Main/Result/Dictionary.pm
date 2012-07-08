package Dict::Learn::Main::Result::Dictionary 0.1;
use base qw[ DBIx::Class::Core ];
__PACKAGE__->table('dictionary');
__PACKAGE__->add_columns(qw[ dictionary_id dictionary_name language_orig_id language_tr_id
                             note cdate mdate ]);
__PACKAGE__->set_primary_key('dictionary_id');
__PACKAGE__->has_one( language_orig_id => 'Dict::Learn::Main::Result::Language', 'language_id');
__PACKAGE__->has_one( language_tr_id   => 'Dict::Learn::Main::Result::Language', 'language_id');

1;

