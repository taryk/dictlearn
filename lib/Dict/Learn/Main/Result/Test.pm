package Dict::Learn::Main::Result::Test;
use base 'DBIx::Class::Core';

=head1 NAME

Dict::Learn::Main::Result::Test

=head1 DESCRIPTION

TODO add description

=cut

__PACKAGE__->table('test');
__PACKAGE__->add_columns(qw( test_id name lang_id enabled cdate mdate ));
__PACKAGE__->set_primary_key('test_id');
__PACKAGE__->has_one(
    lang_id => 'Dict::Learn::Main::Result::Language',
    {'foreign.language_id' => 'self.lang_id'},
    {   cascade_delete => 0,
        cascade_update => 0
    }
);
__PACKAGE__->has_many(
    sessions => 'Dict::Learn::Main::Result::TestSession',
    {'foreign.test_id' => 'self.test_id'},
    {   cascade_delete => 0,
        cascade_update => 0
    }
);
__PACKAGE__->has_many(
    categories => 'Dict::Learn::Main::Result::TestCategory',
    { 'foreign.test_id' => 'self.test_id' },
    {
        cascade_delete => 0,
        cascade_update => 0
    }
);

1;
