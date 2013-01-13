# Dictlearn

The tool for improving and expanding your vocabulary

## Dependencies

* [perl 5.16](http://www.perl.org/get.html)
* [Wx](https://metacpan.org/module/Wx)
* [DBIx::Class](https://metacpan.org/module/DBIx::Class)
* [LWP::UserAgent](https://metacpan.org/module/LWP::UserAgent)
* [JSON](https://metacpan.org/module/JSON)
* [Data::Printer](https://metacpan.org/module/Data::Printer)
* [Class::XSAccessor](https://metacpan.org/module/Class::XSAccessor)
* [common::sense](https://metacpan.org/module/common::sense)
* [namespace::autoclean](https://metacpan.org/module/namespace::autoclean)
* [IOC::Slinky::Container](https://metacpan.org/module/IOC::Slinky::Container)
* [Class::XSAccessor](https://metacpan.org/module/Class::XSAccessor)
* [DBD::SQLite](https://metacpan.org/module/DBD::SQLite)
* [Test::Class](https://metacpan.org/module/Test::Class)
* [IO::File](https://metacpan.org/module/IO::File)
* [URI::Escape](https://metacpan.org/module/URI::Escape)
* [List::Util](https://metacpan.org/module/List::Util)

## Install

    $ perl Makefile.PL
    $ make
    $ sudo make install

## Launch

    $ dictlearn.pl

    $ DBIC_TRACE=1 dictlearn.pl # to enable DB debug mode

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
