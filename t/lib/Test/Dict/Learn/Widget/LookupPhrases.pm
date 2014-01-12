package Test::Dict::Learn::Widget::LookupPhrases;

use parent 'Test::Dict::Learn::Frame::Base';
use common::sense;

use Test::More;
use Wx qw[:everything];

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

    # TODO test other filters/commands
}

1;
