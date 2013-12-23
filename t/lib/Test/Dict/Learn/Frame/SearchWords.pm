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
    *Dict::Learn::Widget::LookupPhrases::set_status_text = sub { };

    $self->SUPER::startup();

    ok($self->{frame}, qw{SearchWords page created});
}

sub fields : Tests {
    my ($self) = @_;

    for (
        [qw(parent)               => 'Dict::Learn::Frame'],
        [qw(lookup_phrases)       => 'Dict::Learn::Widget::LookupPhrases'],
        [qw(sidebar)              => 'Dict::Learn::Widget::Sidebar'],
        [qw(cb_add_to_test)       => 'Wx::ComboBox'],
        [qw(st_add_to_test)       => 'Wx::StaticText'],
        [qw(btn_add_to_test)      => 'Wx::Button'],
        [qw(hbox_add_to_test vbox hbox) => 'Wx::BoxSizer'],
        )
    {
        my $type = pop @$_;
        $self->test_field(name => $_, type => $type, is => 'ro') for @$_;
    }
}

1;
