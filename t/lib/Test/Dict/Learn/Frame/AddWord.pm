package Test::Dict::Learn::Frame::AddWord;

use parent 'Test::Class';
use common::sense;

use Data::Printer;
use Test::MockObject;
use Test::More;
use Wx qw[:everything];

use lib::abs qw( ../../../../../../lib );

use Container;
use Database;
use Dict::Learn::Dictionary;
use Dict::Learn::Frame::AddWord;

sub startup : Test(startup => no_plan) {
    my ($self) = @_;

    # Use in-memory DB for this test
    Container->params( dbfile => ':memory:', debug  => 1 );
    Container->lookup('db')->install_schema();

    # Set default dictionary
    Dict::Learn::Dictionary->all();
    Dict::Learn::Dictionary->set(0);

    # Dummy parent object
    # TODO find a module for creating fake object that can return desired ref
    my $parent = bless {} => 'Dict::Learn::Frame';
    *Dict::Learn::Frame::for_each_page = sub { };

    # `Wx::Panel` wants parent frame to be real
    my $frame  = Wx::Frame->new(undef, wxID_ANY, 'Test');
    $self->{frame}
        = Dict::Learn::Frame::AddWord->new($parent, $frame, wxID_ANY,
        wxDefaultPosition, wxDefaultSize, wxTAB_TRAVERSAL);

    # Monkey-patch the `close_page` method as it uses parent object,
    # which isn't a real Dict::Learn::Frame instance in this test
    *Dict::Learn::Frame::AddWord::close_page = sub {};
}

sub after  : Test(teardown) {
    my ($self) = @_;

    $self->{frame}->word_src->Clear;
}

sub fields : Tests {
    my ($self) = @_;

    my $item_id = 1;
    for (
        [item_id => 'Int'],
        [enable  => 'Bool'],
        [edit_origin => 'HashRef']
        )
    {
        my ($field, $type) = @$_;
        $self->test_field( name => $field, type => $type );
    }

    for (
        [parent       => 'Dict::Learn::Frame'],
        [cb_irregular => 'Wx::CheckBox'],
        [translations => 'Dict::Learn::Frame::AddWord::Translations'],
        [qw(word_note word_src word2_src word3_src) => 'Wx::TextCtrl'],
        [qw(vbox_src hbox_btn hbox_words vbox)      => 'Wx::BoxSizer'],
        [qw(btn_add_word btn_translate btn_clear btn_cancel) => 'Wx::Button'],
        )
    {
        my $type = pop @$_;
        $self->test_field( name => $_, type => $type, is => 'ro') for @$_;
    }
}

sub check_for_duplicates : Tests {
    my ($self) = @_;

    my %item = (
        lang_id      => 1,
        note         => '',
        partofspeech => 0,
        word         => 'test',
        word_id      => undef,
    );

    subtest 'Check for duplicates of the words' => sub {
        my @different_words = (
            { %item, word => 'test1' },
            { %item, word => 'test2' },
        );
        ok(
            !$self->{frame}->check_for_duplicates(\@different_words),
            q{There are no duplicates in @different_words}
        );

        my @duplicate_words = (\%item, \%item);
        is_deeply(
            $self->{frame}->check_for_duplicates(\@duplicate_words), \%item,
            q{It's a duplication if two identical items passed}
        );
    };

    my %item_with_word_id = (
        %item,
        word    => undef,
        word_id => 1,
    );

    subtest 'Check for duplicates of the word_id' => sub {
        my @different_word_id = (
            { %item_with_word_id, word_id => 2 },
            { %item_with_word_id, word_id => 3 },
        );
        ok(
            !$self->{frame}->check_for_duplicates(\@different_word_id),
            q{There are no duplicates in @different_word_id}
        );

        my @duplicate_word_id = (\%item_with_word_id, \%item_with_word_id);
        is_deeply(
            $self->{frame}->check_for_duplicates(\@duplicate_word_id),
            \%item_with_word_id,
            q{It's a duplication if two identical word_id passed}
        );
    };
}

sub add_record : Tests {
    my ($self) = @_;

    my $from_lang_id
        = Dict::Learn::Dictionary->curr->{language_orig_id}{language_id};
    my $to_lang_id
        = Dict::Learn::Dictionary->curr->{language_tr_id}{language_id};

    my %phrase = (
        word => 'Test Word',
        note => 'Test Note',
        translations => [
            {
                word  => 'Test Translation 1',
                partofspeech_id => 1,
            },
            {
                word  => 'Test Translation 2',
                partofspeech_id => 2,
            }
        ],
    );

    $self->add_word_with_translations(%phrase);

    # Check if source word has been added to the database
    my $phrase_dbix = Database->schema->resultset('Word')->match(
        $from_lang_id,
        $phrase{word}
    )->first;

    ok(defined $phrase_dbix, 'DB row was added');

    # Go through the translations
    my @translations = $phrase_dbix->words;
    for my $tr_record (@{ $phrase{translations} }) {
        my ($found_record)
            = grep { $_->word eq $tr_record->{word} } @translations;
        ok($found_record,
            'Translation "' . $found_record->word . '" was added');
        is(
            $found_record->partofspeech_id => $tr_record->{partofspeech_id},
            q{Part-of-speech was set correctly}
        );
        is(
            $found_record->lang_id => $to_lang_id,
            q{lang_id was set correctly}
        );
    }

    # At first, frame is enabled
    is($self->{frame}->enable => 1, q{Frame is enabled});

    # Try to put the word which already exists in the database to 'word_src'
    # field.
    $self->{frame}->word_src->SetValue($phrase{word});

    # After that, frame should become disabled
    is($self->{frame}->enable => 0,
        q{Frame is disabled as long as such word already exists in the database}
    );

    # 'add' method shouldn't neither add the record to the database,
    # nor return true
    ok(!$self->{frame}->add(),
        q{'add' fails to add a word which already is in the database});

    # There's only one record with such a word, which was added by the first
    # 'add' method call
    is(
        Database->schema->resultset('Word')
            ->search({ word => $phrase{word}, lang_id => $from_lang_id })
            ->count() => 1,
        q{The second 'add' call haven't added a record to the database}
    );

}

sub strip_spaces : Tests {
    my ($self) = @_;

    subtest '`strip_spaces` removes leading and trailing spaces' => sub {
        for ($self->strip_spaces_data()) {
            my ($input_value, $output_value) = @$_;
            is(
                $self->{frame}->strip_spaces($input_value) => $output_value,
                qq{input: "$input_value", output: "$output_value"}
            );
        }
    };
}

sub set_word : Tests {
    my ($self) = @_;

    my $word = 'test';
    $self->{frame}->set_word($word);
    is($self->{frame}->word_src->GetValue, $word,
      q{`set_word` sets the value to `word_src` field});

    subtest '`set_word` removes leading and trailing spaces' => sub {
        for ($self->strip_spaces_data()) {
            my ($input_value, $output_value) = @$_;

            $self->{frame}->set_word($input_value);
            is($self->{frame}->word_src->GetValue => $output_value,
                qq{input: "$input_value", output: "$output_value"});
        }
    };
}

sub check_word : Tests {
    my ($self) = @_;

    my $word = 'first-of-its-kind';

    my $from_lang_id
        = Dict::Learn::Dictionary->curr->{language_orig_id}{language_id};

    # insert a new word
    $self->_new_word_in_db(
        {
            word            => $word,
            lang_id         => $from_lang_id,
            partofspeech_id => 0,
        }
    );

    is($self->{frame}->enable, 1, q{At the beginning, form is enabled});

    # if the word already exists in the database, the form controls have to be
    # disabled
    $self->{frame}->check_word(
        $self->_create_event_object($word));

    is($self->{frame}->enable, 0, q{Form has been disabled});
    like($self->{frame}->btn_add_word->GetLabel => qr{^Edit word},
         q{The button label has been changed to 'Edit word...'});

    # Try to pass a word that doesn't exist in the database.
    # The form controls have to be enabled again in the end.
    $self->{frame}->check_word(
        $self->_create_event_object($word.'0'));

    is($self->{frame}->enable, 1, q{Form has been enabled});
    is($self->{frame}->btn_add_word->GetLabel => 'Add',
       q{The button label has been changed to 'Add'});
}

sub _create_event_object {
    my ($self, $word) = @_;

    my $event = Test::MockObject->new();
    $event->mock( GetString => sub { $word } );

    return $event;
}

sub _new_word_in_db {
    my ($self, $word) = @_;

    Database->schema->resultset('Word')->create($word);
}

# input/output values for strip_spaces testing
sub strip_spaces_data {
    return (
        ['phrase  '   => 'phrase'],
        ['  phrase'   => 'phrase'],
        ['  phrase  ' => 'phrase'],
    );
}

sub add_word_with_translations {
    my ($self, %phrase) = @_;

    # Set a source word
    $self->{frame}->word_src->SetValue($phrase{word});

    # Set a note for source word
    $self->{frame}->word_note->SetValue($phrase{note});

    # Add all translations
    for (@{ $phrase{translations} }) {
        $self->{frame}->translations->add_item(%$_);
    }

    # Perform adding
    ok($self->{frame}->add(),
        q{'add' method returns true if a word has been added successfully});
    $self->{frame}->clear_fields();
}

sub test_field {
    my ($self, %params) = @_;

    my $field = delete $params{name};
    $params{is} //= 'rw';

    my $value;
    if ($params{is} eq 'rw') {
        given ($params{type}) {
            when ('Bool')     { $value = 1 }
            when ('Int')      { $value = 3 }
            when ('ArrayRef') { $value = [1 .. 9] }
            when ('HashRef')  { $value = { key => 'value' } }
            when (['Str', undef]) { $value = 'test' }
            default { $value = bless {} => $params{type} }
        }
    }
    subtest $field => sub {
        ok($self->{frame}->$field($value), qq{We can set '$field'})
            if $params{is} eq 'rw';
        my $attr = $self->{frame}->meta->get_attribute($field);
        if ($params{type}) {
            ok($attr->has_type_constraint, qq{$field has a type constraint});
            is($attr->type_constraint, $params{type}, qq{It's $params{type}});
        }
        ok(defined $self->{frame}->$field, q{We can get a value})
            if $params{is} eq 'rw'
            || $attr->has_default
            || $attr->has_builder;
    };
}

1;
