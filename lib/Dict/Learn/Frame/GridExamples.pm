package Dict::Learn::Frame::GridExamples 0.1;

use Wx qw[:everything];
use Wx::Grid;
use Wx::Event qw[:everything];

use base 'Wx::Panel';

use Data::Printer;

use common::sense;

use constant {
  COL_EXAMPLE => 0,
  COL_REL_E   => 1,
  COL_REL_W   => 2,
  COL_CDATE   => 3,
  COL_MDATE   => 4,
};

use Class::XSAccessor
  accessors => [ qw| parent
                     grid vbox hbox_btn btn_delete_item btn_clear_all
                     btn_refresh
               | ];

sub new {
  my $class = shift;
  my $self  = $class->SUPER::new( splice @_ => 1 );
  $self->parent( shift );

  $self->vbox( Wx::BoxSizer->new( wxVERTICAL ) );
  $self->SetSizer( $self->vbox );

  $self->grid( Wx::Grid->new( $self, wxID_ANY, wxDefaultPosition, wxDefaultSize, 0 ) );
  $self->vbox->Add( $self->grid,  1, wxALL|wxGROW,   5 );
  # grid dimension: COL_MDATE+1 - the last column id + 1
  $self->grid->CreateGrid( 0, COL_MDATE+1 );
  $self->grid->SetColSize(COL_EXAMPLE, 400);
  $self->grid->SetColSize(COL_REL_E,   20);
  $self->grid->SetColSize(COL_REL_W,   20);
  $self->grid->SetColSize(COL_CDATE,   140);
  $self->grid->SetColSize(COL_MDATE,   140);
  $self->grid->EnableEditing( 1 );
  $self->grid->EnableGridLines( 1 );
  $self->grid->EnableDragGridSize( 0 );
  $self->grid->SetMargins( 0, 0 );

  $self->grid->EnableDragColMove( 0 );
  $self->grid->EnableDragColSize( 1 );
  $self->grid->SetColLabelSize( 30 );
  $self->grid->SetColLabelAlignment( wxALIGN_CENTRE, wxALIGN_CENTRE );

  $self->grid->EnableDragRowSize( 1 );
  $self->grid->SetRowLabelSize( 30 );
  $self->grid->SetRowLabelAlignment( wxALIGN_CENTRE, wxALIGN_CENTRE );
  $self->grid->SetColLabelValue(COL_EXAMPLE, 'Example'  );
  $self->grid->SetColLabelValue(COL_REL_E,   'E'        );
  $self->grid->SetColLabelValue(COL_REL_W,   'W'        );
  $self->grid->SetColLabelValue(COL_CDATE,   'Created'  );
  $self->grid->SetColLabelValue(COL_MDATE,   'Modified' );

  # $self->select_words();

  $self->hbox_btn( Wx::BoxSizer->new( wxHORIZONTAL ) );
  $self->btn_delete_item( Wx::Button->new( $self, -1, 'Delete',    [-1, -1] ) );
  $self->btn_clear_all(   Wx::Button->new( $self, -1, 'Clear All', [-1, -1] ) );
  $self->btn_refresh(     Wx::Button->new( $self, -1, 'Refresh',   [-1, -1] ) );
  $self->hbox_btn->Add( $self->btn_delete_item, 0, wxBOTTOM|wxALIGN_LEFT|wxLEFT, 5 );
  $self->hbox_btn->Add( $self->btn_clear_all,   0, wxBOTTOM|wxALIGN_LEFT|wxLEFT, 5 );
  $self->hbox_btn->Add( $self->btn_refresh,     0, wxBOTTOM|wxALIGN_LEFT|wxLEFT, 5 );
  $self->vbox->Add( $self->hbox_btn, 0, wxALL|wxGROW|wxEXPAND, 5 );
  $self->Layout();
  $self->vbox->Fit( $self );

  # events
  EVT_GRID_CMD_CELL_CHANGE( $self, $self->grid,  \&update_word   );
  EVT_BUTTON( $self, $self->btn_refresh,         \&refresh_words );
  EVT_BUTTON( $self, $self->btn_delete_item,     \&delete_word   );

  Dict::Learn::Dictionary->cb(sub {
    my $dict = shift;
    $self->refresh_words;
  });

  $self

}

sub update_word {
  my $self = shift;
  my $obj  = shift;
  my @cols = qw[ word_orig word_tr ];
  printf "%s %d %d\n", $self->grid->GetCellValue($obj->GetRow(), $obj->GetCol()),
                       $obj->GetRow(),
                       $obj->GetCol();
  $main::ioc->lookup('db')->update_word(
    id => $self->grid->GetRowLabelValue( $obj->GetRow() ),
    $cols[$obj->GetCol()] // 0 => $self->grid->GetCellValue( $obj->GetRow() ,
                                                             $obj->GetCol()),
  );
}

sub update_example {
  my $self = shift;
  # @TODO: implement
}

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
  $main::ioc->lookup('db')->delete_word( @ids );
  $self->refresh_words();
}

sub delete_example {
  my $self = shift;
  # @TODO: implement
}

sub clear_db {
  my $self = shift;
  # @TODO: implement
}

sub select_words {
  my $self = shift;
  my $i=0;
  my @items = $main::ioc->lookup('db')->select_examples_grid(
    dictionary_id => Dict::Learn::Dictionary->curr_id
  );
  $self->grid->InsertRows(0 , scalar @items);
  # Dict::Learn::Dictionary->curr->{language_orig_id}{language_id}
  for my $item ( $main::ioc->lookup('db')->select_examples_grid(
    dictionary_id => Dict::Learn::Dictionary->curr_id ))
  {
    $self->grid->SetRowLabelValue($i => $item->{example_id}             );
    $self->grid->SetCellValue( $i,   COL_EXAMPLE, $item->{example}      );
    $self->grid->SetCellValue( $i,   COL_REL_E,   $item->{rel_examples} );
    $self->grid->SetCellValue( $i,   COL_REL_W,   $item->{rel_words}    );
    $self->grid->SetCellValue( $i,   COL_CDATE,   $item->{mdate}        );
    $self->grid->SetCellValue( $i++, COL_MDATE,   $item->{cdate}        );
  }
}

sub refresh_words {
  my $self = shift;
  $self->grid->ClearGrid();
  $self->grid->DeleteRows(0, $self->grid->GetNumberRows());
  $self->select_words();
}

1;
