package Test::Dict::Learn::Frame::TranslationTest;

use parent 'Test::Dict::Learn::Frame::Base';
use common::sense;

use Test::More;
use Wx qw[:everything];

use lib::abs qw( ../../../../../../lib );

use Dict::Learn::Frame::TranslationTest;

sub startup : Test(startup => no_plan) {
    my ($self) = @_;

    my $parent = bless {} => 'Dict::Learn::Frame';

    # `Wx::Panel` wants parent frame to be real
    my $frame = Wx::Frame->new(undef, wxID_ANY, 'Test');

    $self->{frame}
        = Dict::Learn::Frame::TranslationTest->new($parent, $frame, wxID_ANY,
        wxDefaultPosition, wxDefaultSize, wxTAB_TRAVERSAL);

    $self->SUPER::startup();

    ok($self->{frame}, qw{TranslationTest page created});
}

sub fields : Tests {
    my ($self) = @_;

    for (
        [qw(parent)                    => 'Dict::Learn::Frame'],
        [qw(min)                       => 'Int'],
        [qw(test_category)             => 'Wx::ComboBox'],
        [qw(spin)                      => 'Wx::SpinCtrl'],
        [qw(position text translation) => 'Wx::StaticText'],
        [qw(input)                     => 'Wx::TextCtrl'],
        [qw(hbox hbox_position vbox)   => 'Wx::BoxSizer'],
        [qw(btn_prev btn_next btn_reset btn_show_translation) =>'Wx::Button'],
        # [qw(result) => 'Dict::Learn::Frame::TranslationTest::Result'],
        )
    {
        my $type = pop @$_;
        $self->test_field(name => $_, type => $type, is => 'ro') for @$_;
    }

    for (
        [qw(count total_score pos) => 'Int'     ],
        [qw(exercise)              => 'ArrayRef'],
       )
    {
        my $type = pop @$_;
        $self->test_field(name => $_, type => $type, is => 'rw') for @$_;
    }

    # FIXME
    delete $self->{attributes}{result};
    delete $self->{attributes}{max};
}

1;
