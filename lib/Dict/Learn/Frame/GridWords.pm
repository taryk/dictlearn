package Dict::Learn::Frame::GridWords 0.1;

use Wx qw[:everything];
use Wx::Grid;
use Wx::Event qw[:everything];

use base 'Wx::Panel';

use Data::Printer;

use common::sense;

use Class::XSAccessor
  accessors => [ qw| parent
                     grid panel2_vbox panel2_hbox_btn btn_delete_item btn_clear_all
                     btn_refresh
               | ];

sub new {
  my $class = shift;
  my $self  = $class->SUPER::new( splice @_ => 1 );
  $self->parent( shift );

  $self->panel2_vbox( Wx::BoxSizer->new( wxVERTICAL ) );
  $self->SetSizer( $self->panel2_vbox );

  $self->grid( Wx::Grid->new( $self, wxID_ANY, wxDefaultPosition, wxDefaultSize, 0 ) );
  $self->panel2_vbox->Add( $self->grid,  1, wxALL|wxGROW,   5 );
  $self->grid->CreateGrid( 0, 5 );
  $self->grid->SetColSize(0, 200);
  $self->grid->SetColSize(1, 25);
  $self->grid->SetColSize(2, 200);
  $self->grid->SetColSize(3, 100);
  $self->grid->SetColSize(4, 100);
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
  $self->grid->SetColLabelValue(0 => 'Word');
  $self->grid->SetColLabelValue(1 => 'wc');
  $self->grid->SetColLabelValue(2 => 'Word tr');
  $self->grid->SetColLabelValue(3 => 'Created');
  $self->grid->SetColLabelValue(4 => 'Modified');

  $self->select_words();

  $self->panel2_hbox_btn( Wx::BoxSizer->new( wxHORIZONTAL ) );
  $self->btn_delete_item( Wx::Button->new( $self, -1, 'Delete',    [-1, -1] ) );
  $self->btn_clear_all( Wx::Button->new( $self, -1, 'Clear All',    [-1, -1] ) );
  $self->btn_refresh( Wx::Button->new( $self, -1, 'Refresh',    [-1, -1] ) );
  $self->panel2_hbox_btn->Add( $self->btn_delete_item,  0, wxBOTTOM|wxALIGN_LEFT|wxLEFT, 5 );
  $self->panel2_hbox_btn->Add( $self->btn_clear_all,  0, wxBOTTOM|wxALIGN_LEFT|wxLEFT, 5 );
  $self->panel2_hbox_btn->Add( $self->btn_refresh,  0, wxBOTTOM|wxALIGN_LEFT|wxLEFT, 5 );
  $self->panel2_vbox->Add( $self->panel2_hbox_btn, 0, wxALL|wxGROW|wxEXPAND, 5 );
  $self->Layout();
  $self->panel2_vbox->Fit( $self );

  # events
  EVT_GRID_CMD_CELL_CHANGE( $self, $self->grid,  \&update_word    );
  EVT_BUTTON( $self, $self->btn_refresh,         \&refresh_words  );
  EVT_BUTTON( $self, $self->btn_delete_item,     \&delete_word    );

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
  my @items = $main::ioc->lookup('db')->select_all();
  $self->grid->InsertRows(0 , scalar @items);
  for my $item ( $main::ioc->lookup('db')->select_all() ) {
    $self->grid->SetRowLabelValue($i => $item->{word_id});
    $self->grid->SetCellValue( $i,   0, $item->{word1_id}{word} );
    $self->grid->SetCellValue( $i,   1, $item->{wordclass}{name_orig} );
    $self->grid->SetCellValue( $i,   2, $item->{word2_id}{word} );
    $self->grid->SetCellValue( $i,   3, $item->{mdate} );
    $self->grid->SetCellValue( $i++, 4, $item->{cdate} );
  }
}

sub refresh_words {
  my $self = shift;
  $self->grid->ClearGrid();
  $self->grid->DeleteRows(0, $self->grid->GetNumberRows());
  $self->select_words();
}

1;
