package Dict::Learn::Frame::TestSummary 0.1;

use Wx qw[:everything];
use Wx::Grid;
use Wx::Event qw[:everything];

use Moose;
use MooseX::NonMoose;
extends 'Wx::Panel';

use Carp qw[croak confess];
use Const::Fast;
use Data::Printer;

use Database;
use Dict::Learn::Dictionary;

use common::sense;

const my $RES_COUNT    => 10;
const my $TEST_ID      => 0;
const my $COL_DATE     => 0;
const my $COL_SCORE    => 1;
const my $COL_LB_WORD  => 0;
const my $COL_LB_SCORE => 1;

=head1 NAME

Dict::Learn::Frame::TestSummary

=head1 DESCRIPTION

TODO add description

=head1 ATTRIBUTES

=head2 parent

TODO add description

=cut

has parent => (
    is  => 'ro',
    isa => 'Dict::Learn::Frame',
);


=head2 lb_word_score

TODO add description

=cut

has lb_word_score => (
    is         => 'ro',
    isa        => 'Wx::ListCtrl',
    lazy_build => 1,
);

sub _build_lb_word_score {
    my $self = shift;

    my $lb_word_score
        = Wx::ListCtrl->new($self, wxID_ANY, wxDefaultPosition, wxDefaultSize,
        wxLC_REPORT | wxLC_HRULES | wxLC_VRULES);
    $lb_word_score->InsertColumn($COL_LB_WORD, 'Word',
        wxLIST_FORMAT_LEFT, 120);
    $lb_word_score->InsertColumn($COL_LB_SCORE, 'Score',
        wxLIST_FORMAT_LEFT, 90);

    return $lb_word_score;
}


=head2 grid

TODO add description

=cut

has grid => (
    is         => 'ro',
    isa        => 'Wx::Grid',
    lazy_build => 1,
);

sub _build_grid {
    my $self = shift;

    my $grid
        = Wx::Grid->new($self, wxID_ANY, wxDefaultPosition, wxDefaultSize, 0);
    $grid->CreateGrid(0, $RES_COUNT * 3 + 2);
    $grid->SetColSize($COL_DATE,  140);
    $grid->SetColSize($COL_SCORE, 100);
    $grid->EnableGridLines(1);
    $grid->EnableDragGridSize(0);
    $grid->SetMargins(0, 0);
    $grid->EnableDragColMove(0);
    $grid->EnableDragColSize(1);
    $grid->SetColLabelSize(30);
    $grid->SetColLabelAlignment(wxALIGN_CENTRE, wxALIGN_CENTRE);
    $grid->EnableDragRowSize(1);
    $grid->SetRowLabelSize(30);
    $grid->SetRowLabelAlignment(wxALIGN_CENTRE, wxALIGN_CENTRE);

    $grid->SetColLabelValue(0, 'Date');
    $grid->SetColLabelValue(1, 'Score');

    return $grid;
}

=head2 vbox

TODO add description

=cut

has vbox => (
    is         => 'ro',
    isa        => 'Wx::BoxSizer',
    lazy_build => 1,
);

sub _build_vbox {
    my $self = shift;

    my $vbox = Wx::BoxSizer->new(wxVERTICAL);
    $vbox->Add($self->hbox, 1, wxALL | wxEXPAND, 0);

    return $vbox;
}

=head2 hbox

TODO add description

=cut

has hbox => (
    is         => 'ro',
    isa        => 'Wx::BoxSizer',
    lazy_build => 1,
);

sub _build_hbox {
    my $self = shift;

    my $hbox = Wx::BoxSizer->new(wxHORIZONTAL);
    $hbox->Add($self->grid,          3, wxRIGHT | wxEXPAND, 5);
    $hbox->Add($self->lb_word_score, 1, wxALL | wxEXPAND,   0);

    return $hbox;
}

=head1 METHODS

=head2 select_data

TODO add description

=cut

sub select_data {
    my $self     = shift;

    my $i        = 0;
    my @sessions = Database->schema->resultset('TestSession')
        ->get_all($TEST_ID);
    $self->grid->InsertRows(0, scalar @sessions);
    for my $session (@sessions) {
        $self->grid->SetRowLabelValue($i => $session->{test_session_id});
        $self->grid->SetCellValue($i, $COL_DATE, $session->{cdate});
        my $j = $COL_SCORE + 1;
        my $r = {correct => 0, wrong => 0};
        my $k = 0;
        for my $data (@{$session->{data}}) {
            if ($k++ == 0) {
                $self->grid->SetCellValue($i, $j, $data->{word_id}{word});
                $self->grid->SetCellBackgroundColour($i, $j++,
                    Wx::Colour->new(219, 219, 219));
                $k = -1;
            }
            my $cell_value = $data->{data};
            my @color;
            given ($data->{score}) {
                when (0) {
                    @color = (247, 183, 176);
                    $r->{wrong} += 0.5;
                    $cell_value
                        .= '('
                        . ($k < 0
                        ? $data->{word_id}{word2}
                        : $data->{word_id}{word3})
                        . ')'
                }
                when (0.5) {
                    @color = (182, 247, 176);
                    $r->{correct} += 0.5;
                }
            }
            $self->grid->SetCellValue($i, $j, $cell_value);
            $self->grid->SetCellBackgroundColour($i, $j++,
                Wx::Colour->new(@color));
        }
        $self->grid->SetCellValue(
            $i, $COL_SCORE,
            sprintf '%d%% (%d/%d)',
            $r->{correct} * 100 / $RES_COUNT,
            $r->{correct}, $RES_COUNT
        );
        if ($r->{correct} == $RES_COUNT) {
            $self->grid->SetCellBackgroundColour($i, $COL_DATE,
                Wx::Colour->new(182, 247, 176));
            $self->grid->SetCellBackgroundColour($i, $COL_SCORE,
                Wx::Colour->new(182, 247, 176));
        }
        $i++;
    }
}

=head2 select_words_stats

TODO add description

=cut

sub select_words_stats {
    my $self = shift;

    my @stats = Database->schema->resultset('TestSession')
        ->get_words_stats($TEST_ID);
    for my $stat (@stats) {
        my $id = $self->lb_word_score->InsertItem(Wx::ListItem->new);
        $self->lb_word_score->SetItem($id, $COL_LB_WORD, $stat->{word});
        $self->lb_word_score->SetItem($id, $COL_LB_SCORE,
            sprintf '%d%% (%d/%d)',
            $stat->{perc}, $stat->{sumscore}, $stat->{wcount});
    }
}

=head2 refresh_data

TODO add description

=cut

sub refresh_data {
    my $self = shift;

    $self->grid->ClearGrid();
    $self->grid->DeleteRows(0, $self->grid->GetNumberRows());
    $self->select_data();
    $self->select_words_stats();
}

sub FOREIGNBUILDARGS {
    my ($class, $parent, @args) = @_;

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

    Dict::Learn::Dictionary->cb(
        sub {
            my $dict = shift;
            $self->refresh_data();
        }
    );
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
