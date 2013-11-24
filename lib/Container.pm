package Container;

use IOC::Slinky::Container;

use common::sense;

my %params;

sub params { shift; %params = @_ }

sub ioc {
    return state $ioc //= IOC::Slinky::Container->new(
        config => {
            container => {
                schema => {
                    _class            => 'Dict::Learn::Main',
                    _constructor      => 'connect',
                    _constructor_args => [
                        "dbi:SQLite:$params{dbfile}",
                        '', '',
                        {   sqlite_unicode => 1,
                            loader_options => {
                                debug => $params{debug},
                                use_namespaces => 1
                            }
                        }
                    ]
                },
                db => {
                    _class            => 'Dict::Learn::Db',
                    _constructor      => 'new',
                    _constructor_args => [
                        schema => { _ref => 'schema' },
                    ],
                },
                dictionary => {
                    _class            => 'Dict::Learn::Dictionary',
                    _constructor      => 'new',
                    _constructor_args => [{_ref => 'db'},]
                },

            },
        }
    );
}

sub lookup { shift; ioc->lookup(@_) }

1;
