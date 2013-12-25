package Test::Dict::Learn::Frame::IrregularVerbsTest;

use parent 'Test::Dict::Learn::Frame::Base';
use common::sense;

use Test::More;
use Wx qw[:everything];

use lib::abs qw( ../../../../../../lib );

use Dict::Learn::Frame::IrregularVerbsTest;

sub startup : Test(startup => no_plan) {
    my ($self) = @_;

    my $parent = bless {} => 'Dict::Learn::Frame';

    # `Wx::Panel` wants parent frame to be real
    my $frame = Wx::Frame->new(undef, wxID_ANY, 'Test');

    $self->{frame}
        = Dict::Learn::Frame::IrregularVerbsTest->new($parent, $frame, wxID_ANY,
        wxDefaultPosition, wxDefaultSize, wxTAB_TRAVERSAL);

    $self->SUPER::startup();

    ok($self->{frame}, qw{IrregularVerbsTest page created});
}

sub fields : Tests {
    my ($self) = @_;

    for (
        [qw(parent)                      => 'Dict::Learn::Frame'],
        [qw(e_word2 e_word3)             => 'Wx::TextCtrl'],
        [qw(btn_prev btn_next btn_reset) => 'Wx::Button'],
        [qw(l_position l_word res res_word2 res_word3) => 'Wx::StaticText'],
        [qw(hbox_words hbox_res hbox_buttons vbox)     => 'Wx::BoxSizer'],
        )
    {
        my $type = pop @$_;
        $self->test_field(name => $_, type => $type, is => 'ro') for @$_;
    }

    for (
        [qw(p_min p_max p_current total_score) => 'Int'],
        [qw(words exercise)                    => 'ArrayRef'],
        )
    {
        my $type = pop @$_;
        $self->test_field(name => $_, type => $type, is => 'rw') for @$_;
    }
}

1;
