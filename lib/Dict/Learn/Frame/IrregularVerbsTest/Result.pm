package Dict::Learn::Frame::IrregularVerbsTest::Result 0.1;

use Wx qw[:everything];
use Wx::Event qw[:everything];

use Data::Printer;

use base 'Wx::Dialog';

use common::sense;

use Class::XSAccessor accessors => [
    qw| parent
        vbox vbox_result l_top lb_result l_question
        l_correct l_wrong l_total
        hbox_btn btn_ok btn_cancel
      |
];

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);
    $self->parent(shift);

    ### table
    $self->lb_result(
        Wx::ListCtrl->new(
            $self, wxID_ANY,
            wxDefaultPosition, [350, 300],
            wxLC_REPORT | wxLC_HRULES | wxLC_VRULES
        )
    );
    $self->lb_result->InsertColumn(0, 'Indefinite',  wxLIST_FORMAT_LEFT, 100);
    $self->lb_result->InsertColumn(1, 'Past Simple', wxLIST_FORMAT_LEFT, 100);
    $self->lb_result->InsertColumn(2, 'Past Participle',
        wxLIST_FORMAT_LEFT, 100);
    $self->lb_result->InsertColumn(3, 'Score', wxLIST_FORMAT_LEFT, 40);
    $self->l_top(
        Wx::StaticText->new(
            $self,                     wxID_ANY,
            'Here are your answers: ', wxDefaultPosition,
            wxDefaultSize,             wxALIGN_LEFT
        )
    );
    $self->l_question(
        Wx::StaticText->new(
            $self,                               wxID_ANY,
            'Do you want to store the results?', wxDefaultPosition,
            wxDefaultSize,                       wxALIGN_LEFT
        )
    );

    ### result
    $self->l_correct(
        Wx::StaticText->new(
            $self,         wxID_ANY,
            'Correct: 0',  wxDefaultPosition,
            wxDefaultSize, wxALIGN_LEFT
        )
    );
    $self->l_wrong(
        Wx::StaticText->new(
            $self,         wxID_ANY,
            'Wrong: 0',    wxDefaultPosition,
            wxDefaultSize, wxALIGN_LEFT
        )
    );
    $self->l_total(
        Wx::StaticText->new(
            $self,         wxID_ANY,
            'Total: 0',    wxDefaultPosition,
            wxDefaultSize, wxALIGN_LEFT
        )
    );

    # layout
    $self->vbox_result(Wx::BoxSizer->new(wxVERTICAL));
    $self->vbox_result->Add($self->l_correct, 0, wxTOP | wxEXPAND, 5);
    $self->vbox_result->Add($self->l_wrong,   0, wxTOP | wxEXPAND, 5);
    $self->vbox_result->Add($self->l_total,   0, wxTOP | wxEXPAND, 5);

    ### buttons
    $self->btn_ok(
        Wx::Button->new(
            $self, wxID_OK, 'OK', wxDefaultPosition, wxDefaultSize
        )
    );
    $self->btn_cancel(
        Wx::Button->new(
            $self, wxID_CANCEL, 'Cancel', wxDefaultPosition, wxDefaultSize
        )
    );

    # layout
    $self->hbox_btn(Wx::BoxSizer->new(wxHORIZONTAL));
    $self->hbox_btn->Add($self->btn_ok,     0, wxEXPAND, 0);
    $self->hbox_btn->Add($self->btn_cancel, 0, wxEXPAND, 0);

    # layout
    $self->vbox(Wx::BoxSizer->new(wxVERTICAL));
    $self->vbox->Add($self->l_top,       0, wxALL | wxEXPAND, 5);
    $self->vbox->Add($self->lb_result,   1, wxALL | wxGROW,   5);
    $self->vbox->Add($self->vbox_result, 0, wxALL | wxEXPAND, 5);
    $self->vbox->Add($self->l_question,  0, wxALL | wxEXPAND, 5);
    $self->vbox->Add($self->hbox_btn,    0, wxALL | wxEXPAND, 5);

    $self->SetSizer($self->vbox);
    $self->Layout();
    $self->vbox->Fit($self);

    $self;
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
    $self;
}

1;
