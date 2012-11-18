package Dict::Learn::Combo::WordList 0.1;
use base qw[ Wx::PlComboPopup ];

use Wx qw[:everything];
use Wx::Event qw[:everything];

use Data::Printer;

use common::sense;

use Class::XSAccessor
  accessors => [ qw| vbox panel search lb_words | ];

sub Init {
  my $self = shift;
  $self->{item_index} = undef;
}

sub Create {
  my ($self, $parent) = @_;
  # widgets
  $self->panel( Wx::Panel->new( $parent, wxID_ANY, wxDefaultPosition, wxDefaultSize, wxCAPTION, "words") );
  # $self->search( Wx::TextCtrl->new( $self->panel, wxID_ANY, 'test', wxDefaultPosition, wxDefaultSize ) );
  # $self->search->SetEditable(1);
  $self->lb_words( Wx::ListCtrl->new( $self->panel, wxID_ANY, wxDefaultPosition, wxDefaultSize,
                                      wxLC_REPORT|wxLC_HRULES|wxLC_VRULES ) );
  $self->lb_words->InsertColumn(0, 'id', wxLIST_FORMAT_LEFT, 35);
  $self->lb_words->InsertColumn(1, 'word', wxLIST_FORMAT_LEFT, 200);
  $self->initialize_words();
  # layout
  $self->vbox( Wx::BoxSizer->new( wxVERTICAL ) );
  # $self->vbox->Add( $self->search, 0, wxEXPAND|wxTOP|wxLEFT|wxRIGHT, 2 );
  $self->vbox->Add( $self->lb_words, 1, wxEXPAND|wxTOP|wxLEFT|wxRIGHT, 2 );
  # main
  $self->panel->SetSizer( $self->vbox );
  $self->panel->Layout();
  $self->vbox->Fit( $self->panel );

  $self->panel
}

sub GetControl {
  my $self = shift;
  # p($self);
  # say "GetControl";
  $self->panel
}

sub OnPopup {
  my $self = shift;
  # Wx::LogMessage( "Popping up" );
}

sub OnDismiss {
  my $self = shift;
  # Wx::LogMessage( "Being dismissed" );
}

sub initialize_words {
  my $self = shift;
  my @words = $main::ioc->lookup('db')->get_all_words(
    Dict::Learn::Dictionary->curr->{language_tr_id}{language_id}
  );
  $self->lb_words->DeleteAllItems();
  for (@words) {
    my $id = $self->lb_words->InsertItem( Wx::ListItem->new );
    $self->lb_words->SetItem($id, 0, $_->{word_id} );
    $self->lb_words->SetItem($id, 1, $_->{word} );
  }
}

1;
