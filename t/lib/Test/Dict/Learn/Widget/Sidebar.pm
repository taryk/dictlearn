package Test::Dict::Learn::Widget::Sidebar;

use parent 'Test::Dict::Learn::Frame::Base';
use common::sense;

use Test::More;
use Wx ':everything';

use lib::abs qw( ../../../../../../lib );

use Dict::Learn::Widget::Sidebar;

sub startup : Test(startup => no_plan) {
    my ($self) = @_;

    # `Wx::Panel` wants parent frame to be real
    my $parent = Wx::Frame->new(undef, wxID_ANY, 'parent');

    $self->{frame}
        = Dict::Learn::Widget::Sidebar->new($parent, wxID_ANY,
        wxDefaultPosition, wxDefaultSize, wxTAB_TRAVERSAL);

    *Dict::Learn::Widget::Sidebar::reload_parent = sub {};

    $self->SUPER::startup();

    ok($self->{frame}, qw{Sidebar panel created});
}

sub fields : Tests {
    my ($self) = @_;

    for (
        [qw(parent)            => 'Wx::Window'],
        [qw(html)              => 'Wx::HtmlWindow'],
        [qw(hbox_buttons vbox) => 'Wx::BoxSizer'],
        [
            qw(btn_edit_word btn_unlink_word btn_delete_word btn_refresh) =>
                'Wx::Button'
        ],
        )
    {
        my $type = pop @$_;
        $self->test_field(name => $_, type => $type, is => 'ro') for @$_;
    }
    for ([qw(word_id) => 'Int']) {
        my $type = pop @$_;
        $self->test_field(name => $_, type => $type, is => 'rw') for @$_;
    }
}

sub delete_word_button_click : Tests {
    my ($self) = @_;

    my @phrases = qw(Test_phrase_1 Test_phrase_2 Test_phrase_3);
    my @phrases_dbix = map { $self->_new_word_in_db(word => $_) } @phrases;

    my $delete_phrase_idx = 1;
    $self->{frame}->word_id($phrases_dbix[$delete_phrase_idx]->word_id);
    $self->{frame}->delete_word();
    for my $phrase (grep { $_ ne $phrases[$delete_phrase_idx] } @phrases) {
        ok(
            $self->_lookup_in_db(word => $phrase),
            "'$phrase' has not been deleted"
        );
    }
    ok(
        !$self->_lookup_in_db(word => $phrases[$delete_phrase_idx]),
        "'$phrases[$delete_phrase_idx]' has been deleted"
    );
}

1;
