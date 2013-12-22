package Test::Dict::Learn::Frame::TestEditor;

use parent 'Test::Dict::Learn::Frame::Base';
use common::sense;

use Test::More;
use Wx qw[:everything];

use lib::abs qw( ../../../../../../lib );

use Dict::Learn::Frame::TestEditor;

sub startup : Test(startup => no_plan) {
    my ($self) = @_;

    my $parent = bless {} => 'Dict::Learn::Frame';

    # `Wx::Panel` wants parent frame to be real
    my $frame = Wx::Frame->new(undef, wxID_ANY, 'Test');

    $self->{frame}
        = Dict::Learn::Frame::TestEditor->new($parent, $frame, wxID_ANY,
        wxDefaultPosition, wxDefaultSize, wxTAB_TRAVERSAL);

    *Dict::Learn::Frame::TestEditor::set_status_text = sub { };
    *Dict::Learn::Widget::LookupPhrases::set_status_text = sub { };

    $self->SUPER::startup();

    ok($self->{frame}, qw{TestEditor page created});
}

sub fields : Tests {
    my ($self) = @_;

    for (
        [qw(parent)                 => 'Dict::Learn::Frame'],
        [qw(lookup_phrases)         => 'Dict::Learn::Widget::LookupPhrases'],
        [qw(partofspeech)           => 'HashRef'],
        [qw(test_groups test_words) => 'Wx::ListCtrl'],
        [
            qw(
                hbox_test_groups vbox_test_groups
                vbox_btn hbox
              ) => 'Wx::BoxSizer'
        ],
        [
            qw(
                btn_add_group btn_del_group btn_update_group
                btn_move_left btn_move_right btn_reload
              ) => 'Wx::Button'
        ],
        )
    {
        my $type = pop @$_;
        $self->test_field(name => $_, type => $type, is => 'ro') for @$_;
    }
}

1;
