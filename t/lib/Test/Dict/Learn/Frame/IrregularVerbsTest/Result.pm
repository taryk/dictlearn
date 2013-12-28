package Test::Dict::Learn::Frame::IrregularVerbsTest::Result;

use parent 'Test::Dict::Learn::Frame::Base';
use common::sense;

use Test::More;
use Wx qw[:everything];

use lib::abs qw( ../../../../../../lib );

use Dict::Learn::Frame::IrregularVerbsTest::Result;

sub startup : Test(startup => no_plan) {
    my ($self) = @_;

    # `Wx::Panel` wants parent frame to be real
    my $parent = Wx::Frame->new(undef, wxID_ANY,'Test');

    $self->{frame}
        = Dict::Learn::Frame::IrregularVerbsTest::Result->new($parent, wxID_ANY);

    $self->SUPER::startup();

    ok($self->{frame}, qw{IrregularVerbsTest::Result window created});
}

sub fields : Tests {
    my ($self) = @_;

    for (
        [qw(parent)            => 'Wx::Window'],
        [qw(lb_result)         => 'Wx::ListCtrl'],
        [qw(btn_ok btn_cancel) => 'Wx::Button'],
        [qw(vbox_result hbox_btn vbox)                  => 'Wx::BoxSizer'],
        [qw(l_top l_question l_correct l_wrong l_total) => 'Wx::StaticText'],
        )
    {
        my $type = pop @$_;
        $self->test_field(name => $_, type => $type, is => 'ro') for @$_;
    }
}

1;
