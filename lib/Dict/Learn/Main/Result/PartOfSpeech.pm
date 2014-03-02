package Dict::Learn::Main::Result::PartOfSpeech;
use base 'DBIx::Class::Core';

=head1 NAME

Dict::Learn::Main::Result::PartOfSpeech

=head1 DESCRIPTION

TODO add description

=cut

__PACKAGE__->table('partofspeech');
__PACKAGE__->add_columns(
    qw( partofspeech_id name_orig name_tr abbr
        note cdate mdate )
);
__PACKAGE__->set_primary_key('partofspeech_id');

# __PACKAGE__->belongs_to('word');

1;
