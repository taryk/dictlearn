package Dict::Learn::Frame::GridExamples 0.1;

use Wx qw[:everything];
use Wx::Grid;
use Wx::Event qw[:everything];

use base 'Wx::Panel';

use Data::Printer;

use common::sense;

use constant {
  COL_EXAMPLE => [ 0, 'example'      ],
  COL_REL_E   => [ 1, 'rel_examples' ],
  COL_REL_W   => [ 2, 'rel_words'    ],
  COL_INTEST  => [ 3, 'in_test'      ],
  COL_CDATE   => [ 4, 'cdate'        ],
  COL_MDATE   => [ 5, 'mdate'        ],
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
  # grid dimension: COL_MDATE->[0]+1 - the last column id + 1
  $self->grid->CreateGrid( 0, COL_MDATE->[0]+1 );
  $self->grid->SetColSize(COL_EXAMPLE->[0], 400);
  $self->grid->SetColSize(COL_REL_E->[0],   20);
  $self->grid->SetColSize(COL_REL_W->[0],   20);
  $self->grid->SetColSize(COL_INTEST->[0],  20);
  $self->grid->SetColSize(COL_CDATE->[0],   140);
  $self->grid->SetColSize(COL_MDATE->[0],   140);
  $self->grid->EnableEditing( 1 );
  $self->grid->EnableGridLines( 1 );
  $self->grid->EnableDragGridSize( 0 );
  $self->grid->SetMargins( 0, 0 );

  $self->grid->EnableDragColMove( 0 );
  $self->grid->EnableDragColSize( 1 );
  $self->grid->SetColLabelSize( 30 );
  $self->grid->SetColLabelAlignment( wxALIGN_CENTRE, wxALIGN_CENTRE );

  $self->grid->EnableDragRowSize( 1 );
  $self->grid->SetRowLabelSize( 45 );
  $self->grid->SetRowLabelAlignment( wxALIGN_CENTRE, wxALIGN_CENTRE );
  $self->grid->SetColLabelValue(COL_EXAMPLE->[0], 'Example'  );
  $self->grid->SetColLabelValue(COL_REL_E->[0],   'E'        );
  $self->grid->SetColLabelValue(COL_REL_W->[0],   'W'        );
  $self->grid->SetColLabelValue(COL_INTEST->[0],  't'        );
  $self->grid->SetColLabelValue(COL_CDATE->[0],   'Created'  );
  $self->grid->SetColLabelValue(COL_MDATE->[0],   'Modified' );

  # $self->select_words();

  $self->hbox_btn( Wx::BoxSizer->new( wxHORIZONTAL ) );
  $self->btn_delete_item( Wx::Button->new( $self, wxID_ANY, 'Delete',    wxDefaultPosition, wxDefaultSize ) );
  $self->btn_clear_all(   Wx::Button->new( $self, wxID_ANY, 'Clear All', wxDefaultPosition, wxDefaultSize ) );
  $self->btn_refresh(     Wx::Button->new( $self, wxID_ANY, 'Refresh',   wxDefaultPosition, wxDefaultSize ) );
  $self->hbox_btn->Add( $self->btn_delete_item, 0, wxBOTTOM|wxALIGN_LEFT|wxLEFT, 5 );
  $self->hbox_btn->Add( $self->btn_clear_all,   0, wxBOTTOM|wxALIGN_LEFT|wxLEFT, 5 );
  $self->hbox_btn->Add( $self->btn_refresh,     0, wxBOTTOM|wxALIGN_LEFT|wxLEFT, 5 );
  $self->vbox->Add( $self->hbox_btn, 0, wxALL|wxGROW|wxEXPAND, 5 );
  $self->Layout();
  $self->vbox->Fit( $self );

  # events
  EVT_GRID_CMD_CELL_CHANGE( $self, $self->grid,  \&update_examples  );
  EVT_BUTTON( $self, $self->btn_refresh,         \&refresh_examples );
  EVT_BUTTON( $self, $self->btn_delete_item,     \&delete_examples  );

  Dict::Learn::Dictionary->cb(sub {
    my $dict = shift;
    $self->refresh_examples;
  });

  $self

}

sub update_examples {
  my ($self, $obj) = @_;
  printf "%s %d %d\n", $self->grid->GetCellValue($obj->GetRow(), $obj->GetCol()),
                       $obj->GetRow(),
                       $obj->GetCol();
  my %upd_example = ( example_id => $self->grid->GetRowLabelValue( $obj->GetRow() ) );
  for ($obj->GetCol()) {
    when (COL_EXAMPLE->[0]) {
      $upd_example{text} = $self->grid->GetCellValue( $obj->GetRow(), COL_EXAMPLE->[0] );
    }
    when (COL_INTEST->[0]) {
      $upd_example{in_test} = $self->grid->GetCellValue( $obj->GetRow(), COL_INTEST->[0] );
    }
  }
  $main::ioc->lookup('db')->schema->resultset('Example')->update_one(%upd_example);
}

sub delete_examples {
  my $self = shift;
  my @rows = $self->grid->GetSelectedRows();
  my @ids;
  for (@rows) {
    push @ids => $self->grid->GetRowLabelValue($_);
    printf "delete row #%d id #%d\n", $_,
                                      $self->grid->GetRowLabelValue($_);
  }
  $main::ioc->lookup('db')->schema->resultset('Example')->delete_one( @ids );
  $self->refresh_examples();
}

sub clear_db {
  my $self = shift;
  # @TODO: implement
}

sub select_examples {
  my $self = shift;
  my $i=0;
  my @items = $main::ioc->lookup('db')->schema->resultset('Example')->select_examples_grid(
    lang1_id      => Dict::Learn::Dictionary->curr->{language_orig_id}{language_id},
    dictionary_id => Dict::Learn::Dictionary->curr_id
  );
  $self->grid->InsertRows(0 , scalar @items);
  # Dict::Learn::Dictionary->curr->{language_orig_id}{language_id}
  for my $item ( @items ) {
    $self->grid->SetRowLabelValue($i => $item->{example_id}             );
    $self->grid->SetCellValue( $i,   COL_EXAMPLE->[0], $item->{COL_EXAMPLE->[1]}     );
    $self->grid->SetCellValue( $i,   COL_REL_E->[0],   $item->{COL_REL_E->[1]}       );
    $self->grid->SetReadOnly(  $i,   COL_REL_E->[0],   1);
    $self->grid->SetCellValue( $i,   COL_REL_W->[0],   $item->{COL_REL_W->[1]}       );
    $self->grid->SetReadOnly(  $i,   COL_REL_W->[0],   1);
    $self->grid->SetCellEditor( $i,  COL_INTEST->[0],  Wx::GridCellBoolEditor->new   );
    $self->grid->SetCellRenderer($i, COL_INTEST->[0],  Wx::GridCellBoolRenderer->new );
    $self->grid->SetCellValue( $i,   COL_INTEST->[0],  $item->{COL_INTEST->[1]}      );
    $self->grid->SetCellValue( $i,   COL_CDATE->[0],   $item->{COL_CDATE->[1]}       );
    $self->grid->SetReadOnly(  $i,   COL_CDATE->[0],   1);
    $self->grid->SetCellValue( $i,   COL_MDATE->[0],   $item->{COL_MDATE->[1]}       );
    $self->grid->SetReadOnly(  $i++, COL_MDATE->[0],   1);
  }
}

sub refresh_examples {
  my $self = shift;
  $self->grid->ClearGrid();
  $self->grid->DeleteRows(0, $self->grid->GetNumberRows());
  $self->select_examples();
}

1;
