package Dict::Learn::Main::ResultSet::Wordclass 0.1;
use base 'DBIx::Class::ResultSet';

use namespace::autoclean;

use common::sense;

use Data::Printer;

sub select {
  my ($self, %params) = @_;
  my $args = {};
  if ($params{name}) {
    $args->{-or} = [
      name_orig => { -like => $params{name} },
      name_tr   => { -like => $params{name} },
    ];
  }
  my $rs = $self->search($args,
    { order_by => { -asc => 'wordclass_id' } });
  $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
  $rs->all()
}

1;
