package Dict::Learn::Main::Result::TestSession;
use base qw[ DBIx::Class::Core ];

=head1 NAME

Dict::Learn::Main::Result::TestSession

=head1 DESCRIPTION

TODO add description

=cut

__PACKAGE__->table('test_session');
__PACKAGE__->add_columns(
    qw[ test_session_id test_id score
        cdate mdate ]
);
__PACKAGE__->set_primary_key('test_session_id');
__PACKAGE__->belongs_to(
    test_id => 'Dict::Learn::Main::Result::Test',
    'test_id',
    {   cascade_delete => 0,
        cascade_update => 0
    }
);
__PACKAGE__->has_many(
    data => 'Dict::Learn::Main::Result::TestSessionData',
    {'foreign.test_session_id' => 'self.test_session_id'},
    {   cascade_delete => 0,
        cascade_update => 0
    }
);

1;
