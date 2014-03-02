package Dict::Learn::Main::Result::RelType;
use base 'DBIx::Class::Core';

=head1 NAME

Dict::Learn::Main::Result::RelType

=head1 DESCRIPTION

TODO add description

=cut

__PACKAGE__->table('rel_type');
__PACKAGE__->add_columns(qw( rel_type name note cdate mdate ));
__PACKAGE__->set_primary_key('rel_type');

1;
