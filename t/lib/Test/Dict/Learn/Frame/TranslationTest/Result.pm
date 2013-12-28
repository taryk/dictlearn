package Test::Dict::Learn::Frame::TranslationTest::Result;

use parent 'Test::Dict::Learn::Frame::Base';
use common::sense;

use Test::More;
use Wx qw[:everything];

use lib::abs qw( ../../../../../../lib );

use Dict::Learn::Frame::TranslationTest::Result;

sub startup : Test(startup => no_plan) {
    my ($self) = @_;

    # `Wx::Panel` wants parent frame to be real
    my $parent = Wx::Frame->new(undef, wxID_ANY,'Test');

    $self->{frame}
        = Dict::Learn::Frame::TranslationTest::Result->new($parent, wxID_ANY);

    $self->SUPER::startup();

    ok($self->{frame}, qw{TranslationTest::Result window created});
}

sub fields : Tests {
    my ($self) = @_;

    for (
        [qw(parent)            => 'Wx::Window'],
        [qw(listbox)           => 'Wx::SimpleHtmlListBox'],
        [qw(hbox vbox)         => 'Wx::BoxSizer'],
        [qw(btn_ok btn_cancel) => 'Wx::Button'],
        )
    {
        my $type = pop @$_;
        $self->test_field(name => $_, type => $type, is => 'ro') for @$_;
    }
}

1;
