CREATE TABLE IF NOT EXISTS word (
  `word_id`           INTEGER  PRIMARY KEY ASC AUTOINCREMENT,
  `word`              VARCHAR  NOT NULL DEFAULT '<none>',
  `word2`             VARCHAR  NULL,
  `word3`             VARCHAR  NULL,
  `lang_id`           INTEGER  NOT NULL DEFAULT 0,
  `partofspeech_id`   INTEGER  NOT NULL DEFAULT 0,
  `irregular`         INTEGER  NULL,
  `in_test`           INTEGER  NULL DEFAULT 1,
  `example`           INTEGER  NULL,
  `note`              TEXT,
  `cdate`             DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `mdate`             DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS word_xref (
  `word1_id`          INTEGER  NOT NULL DEFAULT 0,
  `word2_id`          INTEGER  NOT NULL DEFAULT 0,
  `partofspeech_id`   INTEGER  NOT NULL DEFAULT 0,
  `dictionary_id`     INTEGER  NOT NULL DEFAULT 0,
  `category_id`       INTEGER  NOT NULL DEFAULT 0,
  `rel_type`          VARCHAR  NOT NULL DEFAULT 'tran',
  `note`              TEXT,
  `cdate`             DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `mdate`             DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS rel_type (
  `rel_type`          VARCHAR PRIMARY KEY,
  `name`              VARCHAR NOT NULL UNIQUE,
  `note`              TEXT,
  `cdate`             DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `mdate`             DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS partofspeech (
  `partofspeech_id`   INTEGER  PRIMARY KEY ASC AUTOINCREMENT,
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
  `note`                 VARCHAR,
  `score`                REAL     NOT NULL DEFAULT 0,
  `cdate`                DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `mdate`                DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP 
);

CREATE TABLE IF NOT EXISTS test_category (
  `test_category_id`     INTEGER  PRIMARY KEY ASC AUTOINCREMENT,
  `test_id`              INTEGER  NOT NULL DEFAULT 0,
  `dictionary_id`        INTEGER  NOT NULL DEFAULT 0,
  `name`                 VARCHAR,
  `note`                 VARCHAR,
  `cdate`                DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `mdate`                DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP  
);

CREATE TABLE IF NOT EXISTS test_category_word_xref (
  `test_category_id`     INTEGER  NOT NULL DEFAULT 0,
  `word_id`              INTEGER  NOT NULL DEFAULT 0,
  `partofspeech_id`      INTEGER  NOT NULL DEFAULT 0,
  `cdate`                DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `mdate`                DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP  
);

CREATE TABLE IF NOT EXISTS search_history (
  `search_history_id`    INTEGER  PRIMARY KEY ASC AUTOINCREMENT,
  `text`                 VARCHAR,
  `results_count`        INTEGER  NOT NULL DEFAULT 0,
  `dictionary_id`        INTEGER  NOT NULL DEFAULT 0,
  `cdate`                DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `mdate`                DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP  
);

INSERT INTO language (language_id, language_name) VALUES (0, 'English');
INSERT INTO language (language_id, language_name) VALUES (1, 'Ukrainian');

INSERT INTO dictionary (dictionary_id, dictionary_name, language_orig_id, language_tr_id) VALUES (0, 'English-Ukrainian', 0, 1);
INSERT INTO dictionary (dictionary_id, dictionary_name, language_orig_id, language_tr_id) VALUES (1, 'Ukrainian-English', 1, 0);

INSERT INTO partofspeech (partofspeech_id, name_orig, name_tr, abbr) VALUES (0, 'Noun', 'Іменник','n');
INSERT INTO partofspeech (partofspeech_id, name_orig, name_tr, abbr) VALUES (1, 'Verb', 'Дієслово','v');
INSERT INTO partofspeech (partofspeech_id, name_orig, name_tr, abbr) VALUES (2, 'Participle', 'Дієприкметник', 'p');
INSERT INTO partofspeech (partofspeech_id, name_orig, name_tr, abbr) VALUES (3, 'Interjection', 'Вигук', 'i');
INSERT INTO partofspeech (partofspeech_id, name_orig, name_tr, abbr) VALUES (4, 'Pronoun', 'Займенник', 'pro');
INSERT INTO partofspeech (partofspeech_id, name_orig, name_tr, abbr) VALUES (5, 'Preposition', 'Прийменник', 'pre');
INSERT INTO partofspeech (partofspeech_id, name_orig, name_tr, abbr) VALUES (6, 'Adverb', 'Прислівник', 'adv');
INSERT INTO partofspeech (partofspeech_id, name_orig, name_tr, abbr) VALUES (7, 'Conjunction', 'Сполучник', 'c');
INSERT INTO partofspeech (partofspeech_id, name_orig, name_tr, abbr) VALUES (8, 'Adjective', 'Прикметник', 'adj');

INSERT INTO word (word_id, word, lang_id, partofspeech_id) VALUES (0, 'test', 0, 0);
INSERT INTO word (word_id, word, lang_id, partofspeech_id) VALUES (1, 'тест', 1, 0);
INSERT INTO word (word_id, word, lang_id, partofspeech_id) VALUES (2, 'протестуй', 1, 1);

INSERT INTO word_xref (word1_id, word2_id, dictionary_id, partofspeech_id) VALUES (0, 1, 0, 0);
INSERT INTO word_xref (word1_id, word2_id, dictionary_id, partofspeech_id) VALUES (1, 0, 1, 0);
INSERT INTO word_xref (word1_id, word2_id, dictionary_id, partofspeech_id) VALUES (0, 2, 0, 1);
INSERT INTO word_xref (word1_id, word2_id, dictionary_id, partofspeech_id) VALUES (2, 0, 1, 1);

INSERT INTO test (test_id, name, lang_id, enabled) VALUES (0, 'Irregular Verbs Test', 0, 1);
INSERT INTO test (test_id, name, lang_id, enabled) VALUES (1, 'Translation Test', 0, 1);
INSERT INTO test (test_id, name, lang_id, enabled) VALUES (2, 'Preposition Test', 0, 1);

INSERT INTO rel_type (rel_type, name) VALUES ('tran',  'Translation');
INSERT INTO rel_type (rel_type, name) VALUES ('syn',   'Synonym');
INSERT INTO rel_type (rel_type, name) VALUES ('opp',   'Opposite');
INSERT INTO rel_type (rel_type, name, note) VALUES ('irr2', 'Irregular Verb Past', '2nd form');
INSERT INTO rel_type (rel_type, name, note) VALUES ('irr3', 'Irregular Verb Past Participle', '3rd form');
