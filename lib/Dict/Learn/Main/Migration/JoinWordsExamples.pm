package Dict::Learn::Main::Migration::JoinWordsExamples;

use Data::Printer;

use common::sense;

use Database;

=head1 NAME

Dict::Learn::Main::Migration::JoinWordsExamples

=head1 DESCRIPTION

TODO add description

=head1 FUNCTIONS

=head2 down

TODO add description

=cut

sub down {
    my $data_up;

    ## no critic (ValuesAndExpressions::ProhibitLongChainsOfMethodCalls)
    my $max_word_id
        = 1 + Database->schema->resultset('Word')
        ->search({},
        { select => [{ max => 'word_id', -as => 'max_word_id' }] })
        ->first->get_column('max_word_id');

    ## use critic

    for my $e (Database->schema->resultset('Example')->export_data()) {
        push @{ $data_up->{word} } => {
            word_id => $max_word_id + int($e->{example_id}),
            word    => $e->{example},
            in_test => $e->{in_test},
            lang_id => $e->{lang_id},
            example => 1,
            note    => $e->{note},
            cdate   => $e->{cdate},
            mdate   => $e->{mdate},
        };
    }
    for my $es (Database->schema->resultset('Examples')->export_data()) {
        push @{ $data_up->{words} } => {
            word1_id        => $max_word_id + int($es->{example1_id}),
            word2_id        => $max_word_id + int($es->{example2_id}),
            rel_type        => 0,
            category_id     => 0,
            partofspeech_id => 0,
            dictionary_id   => $es->{dictionary_id},
            note            => $es->{note},
            cdate           => $es->{cdate},
            mdate           => $es->{mdate},
        };
    }
    for my $ew (Database->schema->resultset('WordExample')->export_data()) {
        push @{ $data_up->{words} } => {
            word1_id        => $ew->{word_id},
            word2_id        => $max_word_id + int($ew->{example_id}),
            rel_type        => 1,
            category_id     => 0,
            partofspeech_id => $ew->{partofspeech_id},
            dictionary_id   => 0,
            note            => $ew->{note},
            cdate           => $ew->{cdate},
            mdate           => $ew->{mdate},
        };
    }
    $data_up;
}

=head2 up

TODO add description

=cut

sub up {
    my $data_up = shift;
    say 'Import into Word... '
        . (Database->schema->resultset('Word')->import_data($data_up->{word})
        ? 'ok'
        : 'failed');

    say 'Import into Words... '
        . (Database->schema->resultset('Words')
            ->import_data($data_up->{word_xref}) ? 'ok' : 'failed');
}

1;
