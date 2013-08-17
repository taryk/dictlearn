package Dict::Learn::Db 0.1;

use DBIx::Class::QueryLog::Analyzer;
use DBIx::Class::QueryLog;
use Data::Printer;
use Term::ANSIColor ':constants';
use List::MoreUtils 'any';

use common::sense;
use namespace::autoclean;

use Class::XSAccessor accessors => [qw| schema querylog |];

sub REQ_TABLES {
    [   qw| word word_xref example example_xref word_example_xref
            dictionary wordclass language test test_session test_session_data
          |
    ];
}

sub new {
    my $class = shift;

    my $self = bless {} => $class;
    $self->schema(shift);

    # adding QueryLog
    $self->schema->storage->debugobj(
        $self->querylog(DBIx::Class::QueryLog->new));
    $self->schema->storage->debug(1);
    $self;
}

sub analyze {
    my ($self) = @_;

    my $analyzer
        = DBIx::Class::QueryLog::Analyzer->new({querylog => $self->querylog});
    for my $query (@{$analyzer->get_sorted_queries}) {
        printf '%s sec | %d | %s\n',
            RED . ($query->time_elapsed) . RESET,
            $query->count,
            GREEN . $query->sql . RESET;
        say '[ ' . YELLOW . join(', ' => @{$query->params}) . RESET . ' ]';
    }
    $self->querylog->reset;
}

sub reset_analyzer {
    my ($self) = @_;

    $self->querylog->reset;
}

sub check_tables {
    my $self = shift;

    say 'Checking DB...';
    my @tables = grep { $_->[0] eq 'main' }
        map { [(/^["](\w+)["][.]["](\w+)["]$/x)] }
        $self->schema->storage->dbh->tables();
    for my $req_table (@{+REQ_TABLES}) {
        return unless any { $req_table eq $_->[1] } @tables;
    }

    1;
}

sub install_schema {
    my $self = shift;

    say 'Install schema and initial data';
    my $sql = join ' ' => <DATA>;
    for (split ';' => $sql) {
        $self->schema->storage->dbh->do($_);
    }

    1;
}

sub clear_data {
    my $self = shift;

    for ( qw[Word Words Example Examples WordExample
             TestSession TestSessionData] )
    {
        $self->schema->resultset($_)->clear_data();
    }

    1;
}

sub clear_test_results {
    my $self = shift;

    for (qw[TestSession TestSessionData]) {
        $self->schema->resultset($_)->clear_data();
    }

    1;
}

sub clear_all {
    my $self = shift;

    for (
        qw[Word Words Example Examples WordExample
        Language Wordclass Dictionary
        Test TestSession TestSessionData]
        )
    {
        $self->schema->resultset($_)->clear_data();
    }

    1;
}

1;

__DATA__
CREATE TABLE IF NOT EXISTS word (
  `word_id`           INTEGER  PRIMARY KEY ASC AUTOINCREMENT,
  `word`              VARCHAR  NOT NULL DEFAULT '<none>',
  `word2`             VARCHAR  NULL,
  `word3`             VARCHAR  NULL,
  `lang_id`           INTEGER  NOT NULL DEFAULT 0,
  `wordclass_id`      INTEGER  NOT NULL DEFAULT 0,
  `irregular`         INTEGER  NOT NULL DEFAULT 0,
  `in_test`           INTEGER  NOT NULL DEFAULT 1,
  `note`              TEXT,
  `cdate`             DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `mdate`             DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS word_xref (
  `word1_id`          INTEGER  NOT NULL DEFAULT 0,
  `word2_id`          INTEGER  NOT NULL DEFAULT 0,
  `wordclass_id`      INTEGER  NOT NULL DEFAULT 0,
  `dictionary_id`     INTEGER  NOT NULL DEFAULT 0,
  `rel_type`          INTEGER  NOT NULL DEFAULT 0,
  `category_id`       INTEGER  NOT NULL DEFAULT 0,
  `note`              TEXT,
  `cdate`             DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `mdate`             DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS example (
  `example_id`        INTEGER  PRIMARY KEY ASC AUTOINCREMENT,
  `example`           TEXT,
  `lang_id`           INTEGER  NOT NULL DEFAULT 0,
  `idioma`            INTEGER  NOT NULL DEFAULT 0,
  `in_test`           INTEGER  NOT NULL DEFAULT 1,
  `note`              TEXT,
  `cdate`             DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `mdate`             DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS example_xref (
  `example1_id`       INTEGER  NOT NULL DEFAULT 0,
  `example2_id`       INTEGER  NOT NULL DEFAULT 0,
  `dictionary_id`     INTEGER  NOT NULL DEFAULT 0,
  `note`              TEXT,
  `cdate`             DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `mdate`             DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS word_example_xref (
  `word_id`           INTEGER  NOT NULL DEFAULT 0,
  `example_id`        INTEGER  NOT NULL DEFAULT 0,
  `wordclass_id`      INTEGER  NOT NULL DEFAULT 0,
  `note`              TEXT,
  `cdate`             DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `mdate`             DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS wordclass (
  `wordclass_id`      INTEGER  PRIMARY KEY ASC AUTOINCREMENT,
  `name_orig`         VARCHAR  NOT NULL DEFAULT '<none>',
  `name_tr`           VARCHAR  NOT NULL DEFAULT '<none>',
  `abbr`              VARCHAR  NOT NULL DEFAULT '<none>',
  `note`              TEXT,
  `cdate`             DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `mdate`             DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS dictionary (
  `dictionary_id`     INTEGER  PRIMARY KEY ASC AUTOINCREMENT,
  `dictionary_name`   VARCHAR  NOT NULL UNIQUE,
  `language_orig_id`  INTEGER  NOT NULL DEFAULT 0,
  `language_tr_id`    INTEGER  NOT NULL DEFAULT 0,
  `note`              TEXT,
  `cdate`             DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `mdate`             DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS language (
  `language_id`       INTEGER  PRIMARY KEY ASC AUTOINCREMENT,
  `language_name`     VARCHAR  NOT NULL UNIQUE,
  `note`              TEXT,
  `cdate`             DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `mdate`             DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS test (
  `test_id`           INTEGER  PRIMARY KEY ASC AUTOINCREMENT,
  `name`              VARCHAR  NOT NULL UNIQUE,
  `lang_id`           INTEGER  NOT NULL DEFAULT 0,
  `enabled`           INTEGER  NOT NULL DEFAULT 1,
  `cdate`             DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `mdate`             DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS test_session (
  `test_session_id`   INTEGER  PRIMARY KEY ASC AUTOINCREMENT,
  `test_id`           INTEGER  NOT NULL DEFAULT 0,
  `score`             REAL     NOT NULL DEFAULT 0,
  `cdate`             DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `mdate`             DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS test_session_data (
  `test_session_data_id` INTEGER  PRIMARY KEY ASC AUTOINCREMENT,
  `test_session_id`      INTEGER  NOT NULL DEFAULT 0,
  `word_id`              INTEGER  NOT NULL DEFAULT 0,
  `data`                 VARCHAR,
  `score`                REAL     NOT NULL DEFAULT 0,
  `cdate`                DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `mdate`                DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO language (language_id, language_name) VALUES (0, 'English');
INSERT INTO language (language_id, language_name) VALUES (1, 'Ukrainian');

INSERT INTO dictionary (dictionary_id, dictionary_name, language_orig_id, language_tr_id) VALUES (0, 'English-Ukrainian', 0, 1);
INSERT INTO dictionary (dictionary_id, dictionary_name, language_orig_id, language_tr_id) VALUES (1, 'Ukrainian-English', 1, 0);

INSERT INTO wordclass (wordclass_id, name_orig, name_tr, abbr) VALUES (0, 'Noun', 'Іменник','n');
INSERT INTO wordclass (wordclass_id, name_orig, name_tr, abbr) VALUES (1, 'Verb', 'Дієслово','v');
INSERT INTO wordclass (wordclass_id, name_orig, name_tr, abbr) VALUES (2, 'Participle', 'Дієприкметник', 'p');
INSERT INTO wordclass (wordclass_id, name_orig, name_tr, abbr) VALUES (3, 'Interjection', 'Вигук', 'i');
INSERT INTO wordclass (wordclass_id, name_orig, name_tr, abbr) VALUES (4, 'Pronoun', 'Займенник', 'pro');
INSERT INTO wordclass (wordclass_id, name_orig, name_tr, abbr) VALUES (5, 'Preposition', 'Прийменник', 'pre');
INSERT INTO wordclass (wordclass_id, name_orig, name_tr, abbr) VALUES (6, 'Adverb', 'Прислівник', 'adv');
INSERT INTO wordclass (wordclass_id, name_orig, name_tr, abbr) VALUES (7, 'Conjunction', 'Сполучник', 'c');
INSERT INTO wordclass (wordclass_id, name_orig, name_tr, abbr) VALUES (8, 'Adjective', 'Прикметник', 'adj');

INSERT INTO word (word_id, word, lang_id, wordclass_id) VALUES (0, 'test', 0, 0);
INSERT INTO word (word_id, word, lang_id, wordclass_id) VALUES (1, 'тест', 1, 0);
INSERT INTO word (word_id, word, lang_id, wordclass_id) VALUES (2, 'протестуй', 1, 1);

INSERT INTO word_xref (word1_id, word2_id, dictionary_id, wordclass_id) VALUES (0, 1, 0, 0);
INSERT INTO word_xref (word1_id, word2_id, dictionary_id, wordclass_id) VALUES (1, 0, 1, 0);
INSERT INTO word_xref (word1_id, word2_id, dictionary_id, wordclass_id) VALUES (0, 2, 0, 1);
INSERT INTO word_xref (word1_id, word2_id, dictionary_id, wordclass_id) VALUES (2, 0, 1, 1);

INSERT INTO example (example_id, example, lang_id) VALUES (0, 'This is a test', 0);
INSERT INTO example (example_id, example, lang_id) VALUES (1, 'Це є тест', 1);
INSERT INTO example (example_id, example, lang_id) VALUES (2, 'Please test it', 0);
INSERT INTO example (example_id, example, lang_id) VALUES (3, 'Будь-ласка, протестуй це', 1);

INSERT INTO example_xref (example1_id, example2_id, dictionary_id) VALUES (0, 1, 0);
INSERT INTO example_xref (example1_id, example2_id, dictionary_id) VALUES (1, 0, 1);
INSERT INTO example_xref (example1_id, example2_id, dictionary_id) VALUES (2, 3, 0);
INSERT INTO example_xref (example1_id, example2_id, dictionary_id) VALUES (3, 2, 1);

INSERT INTO word_example_xref (word_id, example_id) VALUES (0, 0);
INSERT INTO word_example_xref (word_id, example_id) VALUES (1, 1);
INSERT INTO word_example_xref (word_id, example_id) VALUES (0, 2);
INSERT INTO word_example_xref (word_id, example_id) VALUES (2, 3);

INSERT INTO test (test_id, name, lang_id, enabled) VALUES (0, 'Irregular Verbs Test', 0, 1);
