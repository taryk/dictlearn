package Test::Dict::Learn::Frame::AddWord;

use parent 'Test::Class';
use common::sense;

use Data::Printer;
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
    my $parent = bless {} => 'Dict::Learn::Frame';

    # `Wx::Panel` wants parent frame to be real
    my $frame  = Wx::Frame->new(undef, wxID_ANY, 'Test');
    $self->{frame}
        = Dict::Learn::Frame::AddWord->new($parent, $frame, wxID_ANY,
        wxDefaultPosition, wxDefaultSize, wxTAB_TRAVERSAL);

    # Monkey-patch the `close_page` method as it uses parent object,
    # which isn't a real Dict::Learn::Frame instance in this test
    *Dict::Learn::Frame::AddWord::close_page = sub {};
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
        word_id => 1
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
            $self->{frame}->check_for_duplicates(\@duplicate_word_id), \%item_with_word_id,
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

    my %record = (
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
        ]
    );

    $self->add_word_with_translations(%record);

    # Check if source word has been added to the database
    my $word_record = Database->schema->resultset('Word')->match(
        $from_lang_id,
        $record{word}
    )->first;

    ok(defined $word_record, 'DB row was added');

    # Go through the translations
    my @translations = $word_record->words;
    for my $tr_record (@{ $record{translations} }) {
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
    $self->{frame}->word_src->SetValue($record{word});

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
            ->search({ word => $record{word}, lang_id => $from_lang_id })
            ->count() => 1,
        q{The second 'add' call haven't added a record to the database}
    );

}

sub strip_spaces : Tests {
    my ($self) = @_;

    for (
        ['phrase  '   => 'phrase'],
        ['  phrase'   => 'phrase'],
        ['  phrase  ' => 'phrase'],
        )
    {
        my ($input_value, $output_value) = @$_;
        is($self->{frame}->strip_spaces($input_value) => $output_value,
                  q{Remove leading and trailing spaces: }
                . qq{input: "$input_value", output: "$output_value"});
    }
}

sub add_word_with_translations {
    my ($self, %record) = @_;

    # Set a source word
    $self->{frame}->word_src->SetValue($record{word});

    # Set a note for source word
    $self->{frame}->word_note->SetValue($record{note});

    # Add all translations
    for (@{ $record{translations} }) {
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
