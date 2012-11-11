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
  accessors => [ qw| vbox menu_bar menu_dicts status_bar notebook
                     panel1 panel11 panel12 panel2 panel3
                     dictionary dictionaries
               | ];

sub new {
  my $class = shift;
  my $self  = $class->SUPER::new( @_ );

  $self->SetIcon( Wx::GetWxPerlIcon() );
  $self->vbox( Wx::BoxSizer->new( wxVERTICAL ) );
  $self->notebook( Wx::Notebook->new( $self, -1, [-1,-1], [-1,-1], 0 ) );

  $self->dictionaries( $self->init_dicts );

  # main menu
  $self->menu_bar( Wx::MenuBar->new(0) );
  $self->SetMenuBar( $self->menu_bar );
  $self->menu_dicts( Wx::Menu->new );
  $self->menu_bar->Append( $self->menu_dicts, 'Dictionaries' );
  $self->init_menu_dicts( $self->menu_dicts );
  $self->set_dictionary( $self->dictionaries->{0} );

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

  # events
  EVT_CLOSE( $self, \&on_close );

  $self
}

sub init_dicts {
  my $self = shift;
  my $dicts = { };
  for ( $main::ioc->lookup('db')->get_dictionaries() ) {
    $dicts->{ $_->{dictionary_id} } = $_;
  }
  $dicts;
}

sub init_menu_dicts {
  my ($self, $menu) = @_;
  # Wx::MenuItem->new( $self->menu_dicts, wxID_ANY, "Test", "", wxITEM_NORMAL)
  for ( values %{ $self->dictionaries } ) {
    $menu->AppendRadioItem( $_->{dictionary_id}, $_->{dictionary_name} );
    # event
    EVT_MENU( $self, $_->{dictionary_id}, \&dictionary_check );
  }
  $self
}

sub dictionary_check {
  my ($self, $event) = @_;
  # my $menu = $event->GetEventObject();
  my $menu_item = $self->menu_dicts->FindItem( $event->GetId );
  $self->status_bar->SetStatusText(
    "Dictionary '" . $menu_item->GetLabel . "' selected"
  );
  $self->set_dictionary( $event->GetId );
}

sub set_dictionary {
  my ($self, $dictionary) = @_;
  if (ref $dictionary eq 'HASH') {
    $self->dictionary( $dictionary );
  }
  else {
    $self->dictionary( $self->dictionaries->{$dictionary} );
  }
  $main::ioc->lookup('db')->dictionary_id( $self->dictionary->{dictionary_id} );
  $self->panel3->lookup if $self->panel3;
  $self->panel2->refresh_words if $self->panel2;
  $self
}

sub on_close {
  my ( $self, $event ) = @_;
  print "exit\n";
  $self->Destroy;
}

1;
