package Dict::Learn::Main::Result::TestCategory;
use base 'DBIx::Class::Core';

=head1 NAME

Dict::Learn::Main::Result::TestCategory

=head1 DESCRIPTION

TODO add description

=cut

__PACKAGE__->table('test_category');
__PACKAGE__->add_columns(
    qw( test_category_id test_id dictionary_id name cdate mdate )
);
__PACKAGE__->set_primary_key('test_category_id');
__PACKAGE__->has_one(
    test => 'Dict::Learn::Main::Result::Test',
    { 'foreign.test_id' => 'self.test_id' },
    {
        cascade_delete => 0,
        cascade_update => 0
    }
);
__PACKAGE__->has_one(
    dictionary => 'Dict::Learn::Main::Result::Dictionary',
    { 'foreign.dictionary_id' => 'self.dictionary_id' },
    {
        cascade_delete => 0,
        cascade_update => 0
    }
);
__PACKAGE__->has_many(
    words => 'Dict::Learn::Main::Result::TestCategoryWords',
    { 'foreign.test_category_id' => 'self.test_category_id' },
    {
        cascade_delete => 1,
        cascade_update => 1
    }
);

1;
