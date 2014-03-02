package Test::Dict::Learn::Widget::WordList;

use parent 'Test::Dict::Learn::Frame::Base';
use common::sense;

use Test::More;
use Wx ':everything';
use Data::Printer;

use lib::abs qw( ../../../../../../lib );

use Dict::Learn::Widget::WordList;

sub startup : Test(startup => no_plan) {
    my ($self) = @_;

    # Construct a Dict::Learn::Widget::WordList instance
    $self->{frame} = bless {} => 'Dict::Learn::Widget::WordList';
    $self->{frame}->parent(Wx::PopupTransientWindow->new(undef, wxID_ANY));

    $self->SUPER::startup();

    ok($self->{frame}, qw{WordList panel created});
}

sub fields : Tests {
    my ($self) = @_;

    for (
        [qw(parent)   => 'Wx::PopupTransientWindow'],
        [qw(panel)    => 'Wx::Panel'],
        [qw(vbox)     => 'Wx::BoxSizer'],
        [qw(lb_words) => 'Wx::ListCtrl'],
        )
    {
        my $type = pop @$_;
        $self->test_field(name => $_, type => $type, is => 'ro') for @$_;
    }
    for ([qw(initialized) => 'Bool']) {
        my $type = pop @$_;
        $self->test_field(name => $_, type => $type, is => 'rw') for @$_;
    }
}

1;
