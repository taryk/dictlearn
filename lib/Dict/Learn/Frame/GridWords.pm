package Dict::Learn::Frame::GridWords;

use Wx qw[:everything];
use Wx::Grid;
use Wx::Event qw[:everything];

use Moose;
use MooseX::NonMoose;
extends 'Wx::Panel';

use Const::Fast;
use Data::Printer;

use common::sense;

use Database;

const my $COL_WORD         => [0, 'word'];
const my $COL_REL_W        => [1, 'rel_words'];
const my $COL_REL_E        => [2, 'rel_examples'];
const my $COL_PARTOFSPEECH => [3, 'partofspeech'];
const my $COL_INTEST       => [4, 'in_test'];
const my $COL_CDATE        => [5, 'cdate'];
const my $COL_MDATE        => [6, 'mdate'];

=head1 NAME

Dict::Learn::Frame::GridWords

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
    $vbox->Add($self->grid,            1, wxALL | wxEXPAND, 5);
    $vbox->Add($self->panel2_hbox_btn, 0, wxALL | wxEXPAND, 5);

    return $vbox;
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
    $grid->CreateGrid(0, $COL_MDATE->[0] + 1);
    $grid->SetColSize($COL_WORD->[0],         300);
    $grid->SetColSize($COL_REL_W->[0],        20);
    $grid->SetColSize($COL_REL_E->[0],        20);
    $grid->SetColSize($COL_PARTOFSPEECH->[0], 30);
    $grid->SetColSize($COL_INTEST->[0],       20);
    $grid->SetColSize($COL_CDATE->[0],        140);
    $grid->SetColSize($COL_MDATE->[0],        140);
    $grid->EnableEditing(1);
    $grid->EnableGridLines(1);
    $grid->EnableDragGridSize(0);
    $grid->SetMargins(0, 0);

    $grid->EnableDragColMove(0);
    $grid->EnableDragColSize(1);
    $grid->SetColLabelSize(30);
    $grid->SetColLabelAlignment(wxALIGN_CENTRE, wxALIGN_CENTRE);

    $grid->EnableDragRowSize(1);
    $grid->SetRowLabelSize(45);
    $grid->SetRowLabelAlignment(wxALIGN_CENTRE, wxALIGN_CENTRE);
    $grid->SetColLabelValue($COL_WORD->[0],         'Word');
    $grid->SetColLabelValue($COL_REL_W->[0],        'W');
    $grid->SetColLabelValue($COL_REL_E->[0],        'E');
    $grid->SetColLabelValue($COL_PARTOFSPEECH->[0], 'pos');
    $grid->SetColLabelValue($COL_INTEST->[0],       't');
    $grid->SetColLabelValue($COL_CDATE->[0],        'Created');
    $grid->SetColLabelValue($COL_MDATE->[0],        'Modified');

    return $grid;
}

=head2 panel2_hbox_btn

TODO add description

=cut

has panel2_hbox_btn => (
    is         => 'ro',
    isa        => 'Wx::BoxSizer',
    lazy_build => 1,
);

sub _build_panel2_hbox_btn {
    my $self = shift;

    my $panel2_hbox_btn = Wx::BoxSizer->new(wxHORIZONTAL);
    $panel2_hbox_btn->Add($self->btn_delete_item, 0,
        wxBOTTOM | wxALIGN_LEFT | wxLEFT, 5);
    $panel2_hbox_btn->Add($self->btn_clear_all, 0,
        wxBOTTOM | wxALIGN_LEFT | wxLEFT, 5);
    $panel2_hbox_btn->Add($self->btn_refresh, 0,
        wxBOTTOM | wxALIGN_LEFT | wxLEFT, 5);

    return $panel2_hbox_btn;
}


=head2 btn_delete_item

TODO add description

=cut

has btn_delete_item => (
    is      => 'ro',
    isa     => 'Wx::Button',
    lazy    => 1,
    default => sub {
        Wx::Button->new(
            shift, wxID_ANY, 'Delete', wxDefaultPosition, wxDefaultSize
        )
    },
);


=head2 btn_clear_all

TODO add description

=cut

has btn_clear_all => (
    is      => 'ro',
    isa     => 'Wx::Button',
    lazy    => 1,
    default => sub {
        Wx::Button->new(
            shift, wxID_ANY, 'Clear All', wxDefaultPosition, wxDefaultSize
        )
    },
);

=head2 btn_refresh

TODO add description

=cut

has btn_refresh => (
    is      => 'ro',
    isa     => 'Wx::Button',
    lazy    => 1,
    default => sub {
        Wx::Button->new(
            shift, wxID_ANY, 'Refresh', wxDefaultPosition, wxDefaultSize
        )
    },
);

=head1 METHODS

=head2 update_word

TODO add description

=cut

sub update_word {
    my ($self, $obj) = @_;

    my @cols = qw[ word_orig word_tr ];

    printf "%s %d %d\n",
        $self->grid->GetCellValue($obj->GetRow(), $obj->GetCol()),
        $obj->GetRow(),
        $obj->GetCol();

    my %upd_word = (word_id => $self->grid->GetRowLabelValue($obj->GetRow()));

    for ($obj->GetCol()) {
        when ($COL_WORD->[0]) {
            my @words = split qr{ \s* [\/\\\|]+ \s* }x =>
                $self->grid->GetCellValue($obj->GetRow(), $COL_WORD->[0]);
            $upd_word{irregular} = @words > 1 ? 1 : 0;
            $upd_word{word}  = $words[0] if $words[0];
            $upd_word{word2} = $words[1] if $words[1];
            $upd_word{word3} = $words[2] if $words[2];
        }
        when ($COL_INTEST->[0]) {
            $upd_word{in_test}
                = $self->grid->GetCellValue($obj->GetRow(), $COL_INTEST->[0]);
        }
    }

    Database->schema->resultset('Word')
        ->update_one(%upd_word);
}

=head2 delete_word

TODO add description

=cut

sub delete_word {
    my $self = shift;

    my @rows = $self->grid->GetSelectedRows();
    my @ids;
    for (@rows) {
        push @ids => $self->grid->GetRowLabelValue($_);
        printf "delete row #%d id #%d\n", $_,
            $self->grid->GetRowLabelValue($_);

        # $self->grid->DeleteRows($_, 1, -1);
    }
    Database->schema->resultset('Word')->delete_one(@ids);
    $self->refresh_words();
}

=head2 clear_db

TODO add description

=cut

sub clear_db {
    my $self = shift;

    # @TODO: implement
}

=head2 select_words

TODO add description

=cut

sub select_words {
    my $self = shift;

    my $i    = 0;
    my @items
        = Database->schema->resultset('Word')
        ->select_words_grid(
        lang1_id =>
            Dict::Learn::Dictionary->curr->{language_orig_id}{language_id},
        dict_id => Dict::Learn::Dictionary->curr_id,
        );
    $self->grid->InsertRows(0, scalar @items);
    for my $item (@items) {
        my $word
            = $item->{is_irregular}
            ? join(' / ' => $item->{word}, $item->{word2}, $item->{word3})
            : $item->{word};
        $self->grid->SetRowLabelValue($i => $item->{word_id});
        $self->grid->SetCellValue($i, $COL_WORD->[0], $word);
        $self->grid->SetCellValue($i, $COL_PARTOFSPEECH->[0],
            $item->{$COL_PARTOFSPEECH->[1]});
        $self->grid->SetCellValue($i, $COL_REL_W->[0],
            $item->{$COL_REL_W->[1]});
        $self->grid->SetReadOnly($i, $COL_REL_W->[0], 1);
        $self->grid->SetCellValue($i, $COL_REL_E->[0],
            $item->{$COL_REL_E->[1]});
        $self->grid->SetReadOnly($i, $COL_REL_E->[0], 1);
        $self->grid->SetCellEditor($i, $COL_INTEST->[0],
            Wx::GridCellBoolEditor->new);
        $self->grid->SetCellRenderer($i, $COL_INTEST->[0],
            Wx::GridCellBoolRenderer->new);
        $self->grid->SetCellValue($i, $COL_INTEST->[0],
            $item->{$COL_INTEST->[1]});
        $self->grid->SetCellValue($i, $COL_CDATE->[0],
            $item->{$COL_CDATE->[1]});
        $self->grid->SetReadOnly($i, $COL_CDATE->[0], 1);
        $self->grid->SetCellValue($i, $COL_MDATE->[0],
            $item->{$COL_MDATE->[1]});
        $self->grid->SetReadOnly($i++, $COL_MDATE->[0], 1);
    }
}

=head2 refresh_words

TODO add description

=cut

sub refresh_words {
    my $self = shift;

    $self->grid->ClearGrid();
    $self->grid->DeleteRows(0, $self->grid->GetNumberRows());
    $self->select_words();
}

sub FOREIGNBUILDARGS {
    my ($class, $parent, @args) = @_;

    return @args;
}

sub BUILDARGS {
    my ($class, $parent) = @_;

    return {parent => $parent};
}

sub BUILD {
    my ($self, @args) = @_;

    $self->SetSizer($self->vbox);
    $self->Layout();
    $self->vbox->Fit($self);

    # events
    EVT_GRID_CMD_CELL_CHANGE($self, $self->grid, \&update_word);
    EVT_BUTTON($self, $self->btn_refresh,     \&refresh_words);
    EVT_BUTTON($self, $self->btn_delete_item, \&delete_word);

    Dict::Learn::Dictionary->cb(
        sub {
            my $dict = shift;
            $self->refresh_words;
        }
    );
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

