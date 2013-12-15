package Dict::Learn::Main::Result::SearchHistory;
use base qw[ DBIx::Class::Core ];

=head1 NAME

Dict::Learn::Main::Result::SearchHistory

=head1 DESCRIPTION

TODO add description

=cut

__PACKAGE__->table('search_history');
__PACKAGE__->add_columns(qw[ search_history_id text results_count dictionary_id cdate mdate ]);
__PACKAGE__->set_primary_key('search_history_id');

__PACKAGE__->has_one(
    dictionary => 'Dict::Learn::Main::Result::Dictionary',
    { 'foreign.dictionary_id' => 'self.dictionary_id' },
    {
        cascade_delete => 0,
        cascade_update => 0
    }
);

1;
