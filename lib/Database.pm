package Database;

use common::sense;

sub schema { return Container->lookup('db')->schema }

1;
