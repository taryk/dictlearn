package Dict::Learn::Frame::TestSummary 0.1;

use Wx qw[:everything];
use Wx::Grid;
use Wx::Event qw[:everything];

use base 'Wx::Panel';

use Dict::Learn::Dictionary;

use common::sense;
use Carp qw[croak confess];
use Data::Printer;

use Class::XSAccessor
  accessors => [ qw| parent
                     vbox hbox
                     grid lb_word_score
                   | ];

use constant {
  TEST_ID   => 0,
  RES_COUNT => 10,

  COL_DATE  => 0,
  COL_SCORE => 1,

  COL_LB_WORD  => 0,
  COL_LB_SCORE => 1,
};

sub new {
  my $class = shift;
  my $self  = $class->SUPER::new( splice @_ => 1 );
  $self->parent( shift );

  ### grid
  $self->grid( Wx::Grid->new( $self, wxID_ANY, wxDefaultPosition, wxDefaultSize, 0 ) );
  $self->grid->CreateGrid(0, RES_COUNT*3+2 );
  $self->grid->SetColSize( COL_DATE,  140 );
  $self->grid->SetColSize( COL_SCORE, 100 );
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

  $self->grid->SetColLabelValue(0, 'Date' );
  $self->grid->SetColLabelValue(1, 'Score' );

  ### lb word
  $self->lb_word_score( Wx::ListCtrl->new( $self, wxID_ANY, wxDefaultPosition, wxDefaultSize, wxLC_REPORT|wxLC_HRULES|wxLC_VRULES ) );
  $self->lb_word_score->InsertColumn( COL_LB_WORD,  'Word',  wxLIST_FORMAT_LEFT, 120);
  $self->lb_word_score->InsertColumn( COL_LB_SCORE, 'Score', wxLIST_FORMAT_LEFT, 90);

  # layouts
  $self->hbox( Wx::BoxSizer->new( wxHORIZONTAL ) );
  $self->hbox->Add( $self->grid, 3, wxRIGHT|wxEXPAND, 5 );
  $self->hbox->Add( $self->lb_word_score, 1, wxALL|wxGROW, 0 );

  # panel layout
  $self->vbox( Wx::BoxSizer->new( wxVERTICAL ) );
  $self->vbox->Add( $self->hbox, 1, wxALL|wxGROW, 0 );
  $self->SetSizer( $self->vbox );

  $self->Layout();
  $self->vbox->Fit( $self );

  Dict::Learn::Dictionary->cb(sub {
    my $dict = shift;
    $self->refresh_data();
  });

  $self
}


sub select_data {
  my $self = shift;
  my $i = 0;
  my @sessions = $main::ioc->lookup('db')->schema->resultset('TestSession')->get_all( TEST_ID );
  $self->grid->InsertRows(0 , scalar @sessions);
  for my $session ( @sessions ) {
     $self->grid->SetRowLabelValue($i => $session->{test_session_id});
     $self->grid->SetCellValue( $i, COL_DATE, $session->{cdate} );
     my $j = COL_SCORE+1;
     my $r = { correct => 0, wrong => 0 };
     my $k = 0;
     for my $data (@{ $session->{data} }) {
       if ($k++ == 0) {
         $self->grid->SetCellValue( $i, $j, $data->{word_id}{word} );
         $self->grid->SetCellBackgroundColour($i, $j++,  Wx::Colour->new(219, 219, 219));
         $k=-1;
       }
       my $cell_value = $data->{data};
       my @color = ();
       given ($data->{score}) {
         when(0) {
           @color = (247, 183, 176);
           $r->{wrong}+=0.5;
           $cell_value .= '('.($k < 0 ? $data->{word_id}{word2} : $data->{word_id}{word3}).')'
         }
         when(0.5) {
           @color = (182, 247, 176);
           $r->{correct}+=0.5;
         }
       }
       $self->grid->SetCellValue( $i, $j, $cell_value );
       $self->grid->SetCellBackgroundColour($i, $j++, Wx::Colour->new( @color ));
     }
     $self->grid->SetCellValue( $i, COL_SCORE, sprintf "%d%% (%d/%d)",
                                $r->{correct}*100/RES_COUNT, $r->{correct}, RES_COUNT);
     if ($r->{correct} == RES_COUNT) {
       $self->grid->SetCellBackgroundColour($i, COL_DATE,  Wx::Colour->new(182, 247, 176));
       $self->grid->SetCellBackgroundColour($i, COL_SCORE, Wx::Colour->new(182, 247, 176));
     }
     $i++;
  }
}

sub select_words_stats {
  my ($self) = shift;
  my @stats = $main::ioc->lookup('db')->schema->resultset('TestSession')->get_words_stats( TEST_ID );
  for my $stat (@stats) {
    my $id = $self->lb_word_score->InsertItem( Wx::ListItem->new );
    $self->lb_word_score->SetItem( $id, COL_LB_WORD,  $stat->{word}  );
    $self->lb_word_score->SetItem( $id, COL_LB_SCORE, sprintf "%d%% (%d/%d)",
                                   $stat->{perc}, $stat->{sumscore}, $stat->{wcount} );
  }
}

sub refresh_data {
  my $self = shift;
  $self->grid->ClearGrid();
  $self->grid->DeleteRows(0, $self->grid->GetNumberRows());
  $self->select_data();
  $self->select_words_stats();
}

1;
