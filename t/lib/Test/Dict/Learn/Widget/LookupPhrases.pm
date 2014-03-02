package Test::Dict::Learn::Widget::LookupPhrases;

use parent 'Test::Dict::Learn::Frame::Base';
use common::sense;

use Test::More;
use Wx ':everything';

use lib::abs qw( ../../../../../../lib );

use Dict::Learn::Widget::LookupPhrases;

sub startup : Test(startup => no_plan) {
    my ($self) = @_;

    # `Wx::Panel` wants parent frame to be real
    my $parent = Wx::Frame->new(undef, wxID_ANY, 'parent');

    $self->{frame}
        = Dict::Learn::Widget::LookupPhrases->new($parent, wxID_ANY,
        wxDefaultPosition, wxDefaultSize, wxTAB_TRAVERSAL);

    *Dict::Learn::Widget::LookupPhrases::set_status_text = sub { };

    $self->SUPER::startup();

    ok($self->{frame}, qw{LookupPhrases panel created});
}

# clear `word` table before each test
sub clear_db : Test(setup => no_plan) {
    my ($self) = @_;

    Database->schema->resultset('Word')->delete_all();
    is(
        Database->schema->resultset('Word')->count() => 0,
        qq{'word' table has been cleared up}
    );

    # Clear all SearchHistory records
    Database->schema->resultset('SearchHistory')->delete_all();
    is(
        Database->schema->resultset('SearchHistory')->count() => 0,
        qq{'SearchHistory' table has been cleared up}
    );

    # ... and elements
    $self->{frame}->lookup_field->Clear;
}

sub fields : Tests {
    my ($self) = @_;

    for (
        [qw(parent)                           => 'Wx::Window'],
        [qw(lookup_field)                     => 'Wx::ComboBox'],
        [qw(phrase_table)                     => 'Wx::ListCtrl'],
        [qw(btn_lookup btn_reset btn_addword) => 'Wx::Button'],
        [qw(lookup_hbox vbox)                 => 'Wx::BoxSizer'],
        )
    {
        my $type = pop @$_;
        $self->test_field(name => $_, type => $type, is => 'ro') for @$_;
    }
    for ([qw(options) => 'HashRef']) {
        my $type = pop @$_;
        $self->test_field(name => $_, type => $type, is => 'rw') for @$_;
    }
}


sub get_word_forms : Tests {
    my ($self) = @_;

    is_deeply($self->{frame}->_get_word_forms() => [],
        qq{_get_word_forms returns empty arrayref if no parameters passed});

    # TODO test `be` substitutions

    # TODO test suffixes
}

sub lookup : Tests {
    my ($self) = @_;

    my $default_limit    = 1_000;
    my $inserted_records = 1_500;
    for (1 .. $inserted_records) {
        $self->_new_word_in_db( word => "test-$_" );
    }
    my $lookup_phrases = $self->{frame};
    $self->{frame}->lookup_field->SetValue('');
    $self->{frame}->lookup();
    is($self->{frame}->phrase_table->GetItemCount() => $default_limit,
       qq{Empty lookup returns $default_limit records});
    $self->{frame}->lookup_field->SetValue('/all');
    $self->{frame}->lookup();
    is($self->{frame}->phrase_table->GetItemCount() => $inserted_records,
       qq{'/all' command returns all $inserted_records records for given language});

    subtest 'Most relevant records go first' => sub {
        my $word = 'test-order';
        for (
            {
                word         => $word,
                translations => [
                    { word => 'test-order-tr-1', partofspeech_id => 1 },
                    { word => 'test-order-tr-2', partofspeech_id => 2 },
                ]
            },
            { word => "$word $word" },
            { word => "$word $word $word" }
            )
        {
            $self->_new_word_in_db(%$_);
        }
        $self->{frame}->lookup_field->SetValue($word);
        $self->{frame}->lookup();
        is($self->{frame}->phrase_table->GetItemCount() => 4,
          q{Returns all four occurences});
        my $COL_PHRASE   = 1;
        my $phrase_table = $self->{frame}->phrase_table;
        for my $row_id (0 .. 1) {
            is(
                $phrase_table->GetItem($row_id, $COL_PHRASE)->GetText => $word,
                qq{$row_id row is '$word'}
            );
        }
        for my $row_id (2 .. 3) {
            isnt(
                $phrase_table->GetItem($row_id, $COL_PHRASE)->GetText => $word,
                qq{$row_id row isn't '$word'}
            );
        }
    };
    # TODO test other filters/commands
}

sub search_history : Tests {
    my ($self) = @_;
    
    my @phrases_to_look_for = map { "Test-$_" } 0 .. 25;

    my $lookup_phrases = $self->{frame};

    $lookup_phrases->lookup_field->SetValue($phrases_to_look_for[0]);
    $lookup_phrases->lookup();

    is_deeply(
        [ $lookup_phrases->lookup_field->GetStrings ],
        [ $phrases_to_look_for[0] ],
        qq{At first, the only element of SearchHistory is "$phrases_to_look_for[0]"}
    );

    $lookup_phrases->lookup_field->SetValue($phrases_to_look_for[0]);
    $lookup_phrases->lookup();
    is_deeply(
        [ $lookup_phrases->lookup_field->GetStrings ],
        [ $phrases_to_look_for[0] ],
        qq{Looking for the same phrase doesn't add a new element}
    );

    for my $phrase (@phrases_to_look_for) {
        $lookup_phrases->lookup_field->SetValue($phrase);
        $lookup_phrases->lookup();
        is($lookup_phrases->lookup_field->GetString(0),
            $phrase, qq{The next element is "$phrase"});
    }

    my $max_count = 20;
    is($lookup_phrases->lookup_field->GetCount, $max_count,
       qq{Max possible SearchHistory size is $max_count});

    is_deeply(
        [ $lookup_phrases->lookup_field->GetStrings ],
        [ (reverse @phrases_to_look_for)[0 .. 19] ], # 20 last elements
        qq{The elements in SearchHistory are in reverse order}
    );

}

1;
