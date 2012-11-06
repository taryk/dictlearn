package Dict::Learn::Frame 0.1;

use Wx qw[:everything];
use Wx::Grid;
use Wx::Event qw[:everything];

use base 'Wx::Frame';

use Data::Printer;

use File::Basename 'dirname';
use lib dirname(__FILE__).'/../lib/';

use Dict::Learn::Db;
use Dict::Learn::Frame::PageAddItem;
use Dict::Learn::Frame::AddWord;
use Dict::Learn::Frame::AddExample;
use Dict::Learn::Frame::GridWords;
use Dict::Learn::Frame::SearchWords;

use common::sense;

use Class::XSAccessor
  accessors => [ qw| vbox menu_bar status_bar notebook
                     panel1 panel11 panel12 panel2 panel3
                     dictionary
               | ];

sub new {
  my $class = shift;
  my $self  = $class->SUPER::new( @_ );

  $self->SetIcon( Wx::GetWxPerlIcon() );
  $self->vbox( Wx::BoxSizer->new( wxVERTICAL ) );
  $self->notebook( Wx::Notebook->new( $self, -1, [-1,-1], [-1,-1], 0 ) );

  $self->dictionary( $main::ioc->lookup('db')->get_dictionary(0) );

  # p($self->dictionary);

  # page3

  $self->panel3( Dict::Learn::Frame::SearchWords->new( $self, $self->notebook, wxID_ANY, wxDefaultPosition, wxDefaultSize, wxTAB_TRAVERSAL ));
  $self->notebook->AddPage( $self->panel3, "Search", 1 );

  # page11

  $self->panel11( Dict::Learn::Frame::AddWord->new( $self, $self->notebook, wxID_ANY, wxDefaultPosition, wxDefaultSize, wxTAB_TRAVERSAL ));

  $self->notebook->AddPage( $self->panel11, "Word", 0 );

  # page12

  $self->panel12( Dict::Learn::Frame::AddExample->new( $self, $self->notebook, wxID_ANY, wxDefaultPosition, wxDefaultSize, wxTAB_TRAVERSAL ));

  $self->notebook->AddPage( $self->panel12, "Example", 0 );

  # page2

  $self->panel2( Dict::Learn::Frame::GridWords->new( $self, $self->notebook, wxID_ANY, wxDefaultPosition, wxDefaultSize, wxTAB_TRAVERSAL ));
  $self->notebook->AddPage( $self->panel2, "Words", 0 );

  # page1

  $self->panel1( Dict::Learn::Frame::PageAddItem->new( $self, $self->notebook, wxID_ANY, wxDefaultPosition, wxDefaultSize, wxTAB_TRAVERSAL ));

  $self->notebook->AddPage( $self->panel1, "Add item", 0 );

  # tell we want automatic layout
  # $self->SetAutoLayout( 1 );
  $self->vbox->Add( $self->notebook, 1, wxALL|wxEXPAND, 5 );
  $self->SetSizer( $self->vbox );
  # size the window optimally and set its minimal size
  # $self->vbox->Fit( $self );
  # $self->vbox->SetSizeHints( $self );
  $self->status_bar($self->CreateStatusBar( 1, wxST_SIZEGRIP, wxID_ANY ));
  $self->menu_bar(Wx::MenuBar->new(0));
  $self->SetMenuBar( $self->menu_bar );

  # events
  EVT_CLOSE( $self, \&on_close );

  $self
}

sub on_close {
  my ( $self, $event ) = @_;
  print "exit\n";
  $self->Destroy;
}

1;
