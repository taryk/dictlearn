package Test::Dict::Learn::Widget::Sidebar;

use parent 'Test::Dict::Learn::Frame::Base';
use common::sense;

use Test::More;
use Wx qw[:everything];

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

1;
