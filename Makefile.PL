use inc::Module::Install;

name     'Dict-Learn';
all_from 'lib/Dict/Learn.pm';
author   q{Taras Iagniuk <mrtaryk@gmail.net>};
license  'perl';

perl_version '5.014';

requires 'Wx'                              => '0.9914';
requires 'Moose'                           => 0;
requires 'MooseX::NonMoose'                => 0;
requires 'DBD::SQLite'                     => '1.37';
requires 'SQL::Abstract'                   => '1.75';
requires 'DBIx::Class'                     => '0.08204';
requires 'DBIx::Class::QueryLog'           => 0;
requires 'DBIx::Class::QueryLog::Analyzer' => 0;
requires 'DateTime::Format::SQLite'        => 0;
requires 'LWP::UserAgent'                  => '6.04';
requires 'JSON'                            => '2.53';
requires 'Data::Printer'                   => '0.33';
requires 'Class::XSAccessor'               => '1.16';
requires 'lib::abs'                        => 0;
requires 'common::sense'                   => '3.6';
requires 'namespace::autoclean'            => '0.13';
requires 'IOC::Slinky::Container'          => '0.1001';
requires 'Class::XSAccessor'               => '1.16';
requires 'IO::File'                        => '1.14';
requires 'URI::Escape'                     => '3.31';
requires 'List::Util'                      => '1.38';
requires 'List::MoreUtils'                 => 0;
requires 'String::Diff'                    => 0;
requires 'DateTime'                        => 0;
requires 'Mojolicious'                     => 0;
requires 'Term::ANSIColor'                 => 0;
requires 'Memoize'                         => 0;
requires 'Const::Fast'                     => '0.014';

test_requires 'Test::Class'         => '0.37';
test_requires 'Test::More'          => 0;
test_requires 'Test::MockObject'    => 0;
test_requires 'Test::POD'           => '1.22';
test_requires 'POD::Coverage'       => '0.18';
test_requires 'Test::POD::Coverage' => '1.08';

no_index directory => qw| db inc t |;

repository 'http://github.com/taryk/dictlearn';

install_script 'scripts/dictlearn';

# install_as_cpan;
auto_install;

WriteAll();

