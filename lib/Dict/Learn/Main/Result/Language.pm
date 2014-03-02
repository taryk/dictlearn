package Dict::Learn::Main::Result::Language;
use base 'DBIx::Class::Core';

=head1 NAME

Dict::Learn::Main::Result::Language

=head1 DESCRIPTION

TODO add description

=cut

__PACKAGE__->table('language');
__PACKAGE__->add_columns(qw( language_id language_name note cdate mdate ));
__PACKAGE__->set_primary_key('language_id');

1;

