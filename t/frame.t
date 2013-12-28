#!/usr/bin/env perl
use lib::abs 'lib';
use Test::Dict::Learn::Frame::AddWord;
use Test::Dict::Learn::Frame::SearchWords;
use Test::Dict::Learn::Frame::TestEditor;
use Test::Dict::Learn::Frame::TranslationTest;
use Test::Dict::Learn::Frame::TranslationTest::Result;
use Test::Dict::Learn::Frame::IrregularVerbsTest;
use Test::Dict::Learn::Frame::IrregularVerbsTest::Result;

Test::Class->runtests;
