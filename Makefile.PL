use inc::Module::Install;

name     'Dict-Learn';
all_from 'lib/Dict/Learn.pm';
author   q{Taras Yagniuk <mrtaryk@gmail.net>};
license  'perl';

perl_version '5.016';

requires 'Wx'                     => '0.9914';
requires 'DBIx::Class'            => '0.08204';
requires 'LWP::UserAgent'         => '6.04';
requires 'JSON'                   => '2.53';
requires 'Data::Printer'          => '0.33';
requires 'Class::XSAccessor'      => '1.16';
requires 'common::sense'          => '3.6';
requires 'namespace::autoclean'   => '0.13';
requires 'IOC::Slinky::Container' => '0.1001';
requires 'Class::XSAccessor'      => '1.16';
requires 'DBD::SQLite'            => '1.37';
requires 'IO::File'               => '1.16';
requires 'URI::Escape'            => '3.31';
requires 'List::Util'             => '1.25';

test_requires 'Test::Class'       => '0.37';

no_index directory => qw| db inc t |;

repository 'http://github.com/taryk/dictlearn';

install_script 'scripts/dictlearn.pl';

# install_as_cpan;
auto_install;

WriteAll;

