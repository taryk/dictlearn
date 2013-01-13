#!/usr/bin/env perl

use common::sense;

use IOC::Slinky::Container;

use File::Basename 'dirname';
use File::Path 'make_path';

use lib dirname(__FILE__).'/../lib/';

use Dict::Learn;
use Dict::Learn::Main;
use Dict::Learn::Db;

my $dbfile = $ENV{HOME}."/.config/dictlearn/dictlearn.db";

unless (-e $dbfile) {
  my $config_dir = dirname $dbfile;
  make_path($config_dir) unless -d $config_dir;
}

our $ioc = IOC::Slinky::Container->new(
  config => {
    container => {

      schema => {
        _class            => 'Dict::Learn::Main',
        _constructor      => 'connect',
        _constructor_args => [
          "dbi:SQLite:".$dbfile, '', '',
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

      dictionary => {
        _class => 'Dict::Learn::Dictionary',
        _constructor => 'new',
        _constructor_args => [
          { _ref => 'db' },
        ]
      },

    },
});

my $app = Dict::Learn->new;
$app->MainLoop;

