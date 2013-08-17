package Dict::Learn::Frame::IrregularVerbsTest::Result 0.1;

use Wx qw[:everything];
use Wx::Event qw[:everything];

use Moose;
use MooseX::NonMoose;
extends 'Wx::Dialog';

use Data::Printer;

use common::sense;

=item parent

=cut

has parent => (
    is       => 'ro',
    isa      => 'Dict::Learn::Frame::IrregularVerbsTest',
    required => 1,
);

=item lb_result

=cut

has lb_result => (
    is         => 'ro',
    isa        => 'Wx::ListCtrl',
    lazy_build => 1,
);

sub _build_lb_result {
    my $self = shift;

    my $lb_result = Wx::ListCtrl->new(
            $self, wxID_ANY,
            wxDefaultPosition, [350, 300],
            wxLC_REPORT | wxLC_HRULES | wxLC_VRULES
        );
    $lb_result->InsertColumn(0, 'Indefinite',  wxLIST_FORMAT_LEFT, 100);
    $lb_result->InsertColumn(1, 'Past Simple', wxLIST_FORMAT_LEFT, 100);
    $lb_result->InsertColumn(2, 'Past Participle',
        wxLIST_FORMAT_LEFT, 100);
    $lb_result->InsertColumn(3, 'Score', wxLIST_FORMAT_LEFT, 40);

    return $lb_result;
}

=item l_top

=cut

has l_top => (
    is      => 'ro',
    isa     => 'Wx::StaticText',
    lazy    => 1,
    default => sub {
        Wx::StaticText->new(
            shift,                     wxID_ANY,
            'Here are your answers: ', wxDefaultPosition,
            wxDefaultSize,             wxALIGN_LEFT
        )
    },
);

=item l_question

=cut

has l_question => (
    is      => 'ro',
    isa     => 'Wx::StaticText',
    lazy    => 1,
    default => sub {
        Wx::StaticText->new(
            shift,                               wxID_ANY,
            'Do you want to store the results?', wxDefaultPosition,
            wxDefaultSize,                       wxALIGN_LEFT
        )
    },
);

=item l_correct

=cut

has l_correct => (
    is      => 'ro',
    isa     => 'Wx::StaticText',
    lazy    => 1,
    default => sub {
        Wx::StaticText->new(
            shift,         wxID_ANY,
            'Correct: 0',  wxDefaultPosition,
            wxDefaultSize, wxALIGN_LEFT
        )
    },
);

=item l_wrong

=cut

has l_wrong => (
    is      => 'ro',
    isa     => 'Wx::StaticText',
    lazy    => 1,
    default => sub {
        Wx::StaticText->new(
            shift,         wxID_ANY,
            'Wrong: 0',    wxDefaultPosition,
            wxDefaultSize, wxALIGN_LEFT
        )
    },
);

=item l_total

=cut

has l_total => (
    is      => 'ro',
    isa     => 'Wx::StaticText',
    lazy    => 1,
    default => sub {
        Wx::StaticText->new(
            shift,         wxID_ANY,
            'Total: 0',    wxDefaultPosition,
            wxDefaultSize, wxALIGN_LEFT
        )
    },
);

=item vbox_result

=cut

has vbox_result => (
    is         => 'ro',
    isa        => 'Wx::BoxSizer',
    lazy_build => 1,
);

sub _build_vbox_result {
    my $self = shift;

    my $vbox_result = Wx::BoxSizer->new(wxVERTICAL);
    $vbox_result->Add($self->l_correct, 0, wxTOP | wxEXPAND, 5);
    $vbox_result->Add($self->l_wrong,   0, wxTOP | wxEXPAND, 5);
    $vbox_result->Add($self->l_total,   0, wxTOP | wxEXPAND, 5);

    return $vbox_result;
}

=item btn_ok

=cut

has btn_ok => (
    is      => 'ro',
    isa     => 'Wx::Button',
    lazy    => 1,
    default => sub {
        Wx::Button->new(
            shift, wxID_OK, 'OK', wxDefaultPosition, wxDefaultSize
        )
    },
);

=item btn_cancel

=cut

has btn_cancel => (
    is      => 'ro',
    isa     => 'Wx::Button',
    lazy    => 1,
    default => sub {
        Wx::Button->new(
            shift, wxID_CANCEL, 'Cancel', wxDefaultPosition, wxDefaultSize
        )
    },
);

=item hbox_btn

=cut

has hbox_btn => (
    is         => 'ro',
    isa        => 'Wx::BoxSizer',
    lazy_build => 1,
);

sub _build_hbox_btn {
    my $self = shift;

    my $hbox_btn = Wx::BoxSizer->new(wxHORIZONTAL);
    $hbox_btn->Add($self->btn_ok,     0, wxEXPAND, 0);
    $hbox_btn->Add($self->btn_cancel, 0, wxEXPAND, 0);

    return $hbox_btn;
}

=item vbox

=cut

has vbox => (
    is         => 'ro',
    isa        => 'Wx::BoxSizer',
    lazy_build => 1,
);

sub _build_vbox {
    my $self = shift;

    my $vbox = Wx::BoxSizer->new(wxVERTICAL);
    $vbox->Add($self->l_top,       0, wxALL | wxEXPAND, 5);
    $vbox->Add($self->lb_result,   1, wxALL | wxGROW,   5);
    $vbox->Add($self->vbox_result, 0, wxALL | wxEXPAND, 5);
    $vbox->Add($self->l_question,  0, wxALL | wxEXPAND, 5);
    $vbox->Add($self->hbox_btn,    0, wxALL | wxEXPAND, 5);

    return $vbox;
}

sub FOREIGNBUILDARGS {
    my ($class, @args) = @_;

    return @args;
}

sub BUILDARGS {
    my ($class, $parent) = @_;

    return { parent => $parent };
}

sub BUILD {
    my ($self, @args) = @_;

    $self->SetSizer($self->vbox);
    $self->Layout();
    $self->vbox->Fit($self);
}

sub fill_result {
    my ($self, $result) = @_;

    my $res = {
        correct => 0,
        wrong   => 0,
    };
    my $count = scalar @{$result};
    for my $item (@{$result}) {
        my $id = $self->lb_result->InsertItem(Wx::ListItem->new);
        $self->lb_result->SetItem($id, 0, $item->{word}[0]);
        $self->lb_result->SetItem($id, 1, $item->{user}[1][0]);
        $self->lb_result->SetItem($id, 2, $item->{user}[2][0]);
        my @color;
        if ($item->{score} == 0) {
            $res->{wrong} += 1;
            @color = (247, 183, 176);
        }
        elsif ($item->{score} == 0.5) {
            @color = (247, 217, 176);
            $res->{wrong}   += 0.5;
            $res->{correct} += 0.5;
        }
        elsif ($item->{score} == 1) {
            $res->{correct} += 1;
            @color = (182, 247, 176);
        }
        $self->lb_result->SetItemBackgroundColour($id,
            Wx::Colour->new(@color));
        $self->lb_result->SetItem($id, 3, $item->{score});
    }
    $self->l_correct->SetLabel('Correct: ' . $res->{correct});
    $self->l_wrong->SetLabel('Wrong: ' . $res->{wrong});
    $self->l_total->SetLabel(sprintf 'Total: %.1d%%',
        $res->{correct} * 100 / $count);

    return $self;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
