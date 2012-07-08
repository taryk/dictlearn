#!/usr/bin/env perl

use common::sense;

use IOC::Slinky::Container;

use File::Basename 'dirname';

use lib dirname(__FILE__).'/../lib/';

use Dict::Learn;
use Dict::Learn::Main;
use Dict::Learn::Db;

use constant DBFILE => dirname(__FILE__) . '/../db/dictlearn.db';

our $ioc = IOC::Slinky::Container->new(
  config => {
    container => {

      schema => {
        _class            => 'Dict::Learn::Main',
        _constructor      => 'connect',
        _constructor_args => [
          "dbi:SQLite:".DBFILE, '', '',
          { sqlite_unicode => 1,
            loader_options => {
              debug => $ENV{DBIC_TRACE} || 0 ,
              use_namespaces => 1
          } }
      ] },

      db => {
        _class            => 'Dict::Learn::Db',
        _constructor      => 'new',
        _constructor_args => [
          { _ref => 'schema' },
        ],
      },
    },
});

my $app = Dict::Learn->new;
$app->MainLoop;

