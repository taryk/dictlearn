package Dict::Learn::Frame::GridWords 0.1;

use Wx qw[:everything];
use Wx::Grid;

use Wx::Event qw[:everything];

use base 'Wx::Panel';

use Data::Printer;

use common::sense;

use constant {
  COL_WORD      => [ 0, 'word'         ],
  COL_REL_W     => [ 1, 'rel_words'    ],
  COL_REL_E     => [ 2, 'rel_examples' ],
  COL_WORDCLASS => [ 3, 'wordclass'    ],
  COL_INTEST    => [ 4, 'in_test'      ],
  COL_CDATE     => [ 5, 'cdate'        ],
  COL_MDATE     => [ 6, 'mdate'        ],
};

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
  $self->grid->CreateGrid(0, COL_MDATE->[0]+1 );
  $self->grid->SetColSize(COL_WORD->[0],      300 );
  $self->grid->SetColSize(COL_REL_W->[0],     20  );
  $self->grid->SetColSize(COL_REL_E->[0],     20  );
  $self->grid->SetColSize(COL_WORDCLASS->[0], 30  );
  $self->grid->SetColSize(COL_INTEST->[0],    20  );
  $self->grid->SetColSize(COL_CDATE->[0],     140 );
  $self->grid->SetColSize(COL_MDATE->[0],     140 );
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
  $self->grid->SetColLabelValue(COL_WORD->[0],      'Word'     );
  $self->grid->SetColLabelValue(COL_REL_W->[0],     'W'        );
  $self->grid->SetColLabelValue(COL_REL_E->[0],     'E'        );
  $self->grid->SetColLabelValue(COL_WORDCLASS->[0], 'wc'       );
  $self->grid->SetColLabelValue(COL_INTEST->[0],    't'        );
  $self->grid->SetColLabelValue(COL_CDATE->[0],     'Created'  );
  $self->grid->SetColLabelValue(COL_MDATE->[0],     'Modified' );

  # $self->select_words();

  $self->panel2_hbox_btn( Wx::BoxSizer->new( wxHORIZONTAL ) );
  $self->btn_delete_item( Wx::Button->new( $self, wxID_ANY, 'Delete',    wxDefaultPosition, wxDefaultSize ) );
  $self->btn_clear_all(   Wx::Button->new( $self, wxID_ANY, 'Clear All', wxDefaultPosition, wxDefaultSize ) );
  $self->btn_refresh(     Wx::Button->new( $self, wxID_ANY, 'Refresh',   wxDefaultPosition, wxDefaultSize ) );
  $self->panel2_hbox_btn->Add( $self->btn_delete_item,  0, wxBOTTOM|wxALIGN_LEFT|wxLEFT, 5 );
  $self->panel2_hbox_btn->Add( $self->btn_clear_all,    0, wxBOTTOM|wxALIGN_LEFT|wxLEFT, 5 );
  $self->panel2_hbox_btn->Add( $self->btn_refresh,      0, wxBOTTOM|wxALIGN_LEFT|wxLEFT, 5 );
  $self->panel2_vbox->Add(     $self->panel2_hbox_btn,  0, wxALL|wxGROW|wxEXPAND,        5 );
  $self->Layout();
  $self->panel2_vbox->Fit( $self );

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
  my %upd_word = ( word_id => $self->grid->GetRowLabelValue( $obj->GetRow() ) );
  for ($obj->GetCol()) {
    when (COL_WORD->[0]) {
      my @words = split /\s*[\/\\\|]+\s*/ => $self->grid->GetCellValue( $obj->GetRow(), COL_WORD->[0] );
      $upd_word{irregular} = @words > 1 ? 1 : 0;
      $upd_word{word}  = $words[0] if $words[0];
      $upd_word{word2} = $words[1] if $words[1];
      $upd_word{word3} = $words[2] if $words[2];
    }
    when (COL_INTEST->[0]) {
      $upd_word{in_test} = $self->grid->GetCellValue( $obj->GetRow(), COL_INTEST->[0] );
    }
  }
  $main::ioc->lookup('db')->schema->resultset('Word')->update_one(%upd_word);
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
  $main::ioc->lookup('db')->schema->resultset('Word')->delete_one( @ids );
  $self->refresh_words();
}

sub clear_db {
  my $self = shift;
  # @TODO: implement
}

sub select_words {
  my $self = shift;
  my $i=0;
  my @items = $main::ioc->lookup('db')->schema->resultset('Word')->select_words_grid(
    lang1_id => Dict::Learn::Dictionary->curr->{language_orig_id}{language_id},
    dict_id  => Dict::Learn::Dictionary->curr_id,
  );
  $self->grid->InsertRows(0 , scalar @items);
  for my $item ( @items ) {
    my $word = $item->{is_irregular} ?
      join(' / ' => $item->{word}, $item->{word2}, $item->{word3}) :
      $item->{word};
    $self->grid->SetRowLabelValue($i => $item->{word_id});
    $self->grid->SetCellValue( $i,   COL_WORD->[0],      $word );
    $self->grid->SetCellValue( $i,   COL_WORDCLASS->[0], $item->{COL_WORDCLASS->[1]} );
    $self->grid->SetCellValue( $i,   COL_REL_W->[0],     $item->{COL_REL_W->[1]} );
    $self->grid->SetReadOnly(  $i,   COL_REL_W->[0],     1 );
    $self->grid->SetCellValue( $i,   COL_REL_E->[0],     $item->{COL_REL_E->[1]} );
    $self->grid->SetReadOnly(  $i,   COL_REL_E->[0],     1 );
    $self->grid->SetCellEditor( $i,  COL_INTEST->[0],    Wx::GridCellBoolEditor->new );
    $self->grid->SetCellRenderer( $i,COL_INTEST->[0],    Wx::GridCellBoolRenderer->new );
    $self->grid->SetCellValue( $i,   COL_INTEST->[0],    $item->{COL_INTEST->[1]} );
    $self->grid->SetCellValue( $i,   COL_CDATE->[0],     $item->{COL_CDATE->[1]} );
    $self->grid->SetReadOnly(  $i,   COL_CDATE->[0],     1 );
    $self->grid->SetCellValue( $i,   COL_MDATE->[0],     $item->{COL_MDATE->[1]} );
    $self->grid->SetReadOnly(  $i++, COL_MDATE->[0],     1 );
  }
}

sub refresh_words {
  my $self = shift;
  $self->grid->ClearGrid();
  $self->grid->DeleteRows(0, $self->grid->GetNumberRows());
  $self->select_words();
}

1;
