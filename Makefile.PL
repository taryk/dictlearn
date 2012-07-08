use inc::Module::Install;

name     'dictlearn';
all_from 'lib/Dict/Learn.pm';
author   q{Taras Yagniuk <taras@maytech.net>};
license  'perl';

build_requires 'Test::More';

auto_install;

WriteAll;

