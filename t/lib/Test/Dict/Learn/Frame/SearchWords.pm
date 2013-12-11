package Test::Dict::Learn::Frame::SearchWords;

use parent 'Test::Dict::Learn::Frame::Base';
use common::sense;

use Test::More;
use Wx qw[:everything];

use lib::abs qw( ../../../../../../lib );

use Dict::Learn::Frame::SearchWords;

sub startup : Test(startup => no_plan) {
    my ($self) = @_;

    my $parent = bless {} => 'Dict::Learn::Frame';

    # `Wx::Panel` wants parent frame to be real
    my $frame = Wx::Frame->new(undef, wxID_ANY, 'Test');

    $self->{frame}
        = Dict::Learn::Frame::SearchWords->new($parent, $frame, wxID_ANY,
        wxDefaultPosition, wxDefaultSize, wxTAB_TRAVERSAL);

    *Dict::Learn::Frame::SearchWords::set_status_text = sub { };

    $self->SUPER::startup();

    ok($self->{frame}, qw{SearchWords page created});
}

sub fields : Tests {
    my ($self) = @_;

    for (
        [qw(parent)                  => 'Dict::Learn::Frame'],
        [qw(combobox cb_add_to_test) => 'Wx::ComboBox'],
        [qw(sidebar)                 => 'Dict::Learn::Frame::Sidebar'],
        [qw(st_add_to_test)          => 'Wx::StaticText'],
        [qw(lb_words lb_examples)    => 'Wx::ListCtrl'],
        [
            qw(
                  lookup_hbox vbox_btn_words hbox_words
                  vbox_btn_examples hbox_examples
                  hbox_add_to_test
                  vbox hbox
             ) => 'Wx::BoxSizer'
        ],
        [
            qw(
                  btn_lookup btn_reset btn_addword
                  btn_edit_word btn_unlink_word btn_delete_word
                  btn_add_example btn_edit_example btn_unlink_example
                  btn_delete_example btn_add_to_test
             ) => 'Wx::Button'
        ],
        )
    {
        my $type = pop @$_;
        $self->test_field(name => $_, type => $type, is => 'ro') for @$_;
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
        $self->_new_word_in_db({ word => "test-$_" });
    }
    $self->{frame}->combobox->SetValue('');
    $self->{frame}->lookup();
    is($self->{frame}->lb_words->GetItemCount() => $default_limit,
       qq{Empty lookup returns $default_limit records});
    $self->{frame}->combobox->SetValue('/all');
    $self->{frame}->lookup();
    is($self->{frame}->lb_words->GetItemCount() => $inserted_records,
       qq{'/all' command returns all $inserted_records records for given language});

    # TODO test other filters/commands
}

1;
