# Dictlearn

The tool for improving and expanding your vocabulary

## Dependencies

* [perl 5.14](http://www.perl.org/get.html)
* [Wx](https://metacpan.org/module/Wx)
* [DBIx::Class](https://metacpan.org/module/DBIx::Class)
* [DBIx::Class::QueryLog](https://metacpan.org/module/DBIx::Class::QueryLog)
* [DBIx::Class::QueryLog::Analyzer](https://metacpan.org/module/DBIx::Class::QueryLog::Analyzer)
* [Moose](https://metacpan.org/module/Moose)
* [MooseX::NonMoose](https://metacpan.org/module/MooseX::NonMoose)
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
* [List::MoreUtils](https://metacpan.org/module/List::MoreUtils)
* [DateTime::Format::SQLite](https://metacpan.org/module/DateTime::Format::SQLite)
* [String::Diff](https://metacpan.org/module/String::Diff)
* [DateTime](https://metacpan.org/module/DateTime)
* [Mojolicious](https://metacpan.org/module/Mojolicious)
* [Term::ANSIColor](https://metacpan.org/module/Term::ANSIColor)
* [Memoize](https://metacpan.org/module/Memoize)

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
