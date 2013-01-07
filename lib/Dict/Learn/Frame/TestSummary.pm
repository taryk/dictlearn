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
                     vbox
                     grid
                   | ];

use constant {
  TEST_ID   => 0,
  RES_COUNT => 10,

  COL_DATE  => 0,
  COL_SCORE => 1,
};

sub new {
  my $class = shift;
  my $self  = $class->SUPER::new( splice @_ => 1 );
  $self->parent( shift );
  $self->vbox( Wx::BoxSizer->new( wxVERTICAL ) );
  $self->SetSizer( $self->vbox );
  $self->grid( Wx::Grid->new( $self, wxID_ANY, wxDefaultPosition, wxDefaultSize, 0 ) );
  $self->vbox->Add( $self->grid, 1, wxALL|wxGROW, 5 );
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

sub refresh_data {
  my $self = shift;
  $self->grid->ClearGrid();
  $self->grid->DeleteRows(0, $self->grid->GetNumberRows());
  $self->select_data();
}

1;
