package Database;

use common::sense;

sub schema { return $main::ioc->lookup('db')->schema }

1;
