package Dict::Learn::Combo::ExamplesList 0.1;
use base 'Wx::PopupTransientWindow';

use Wx qw[:everything];
use Wx::Event qw[:everything];

use Data::Printer;

use common::sense;

use Class::XSAccessor
  accessors => [ qw| parent vbox search lb_examples cb | ];

sub new {
  my $class = shift;
  my $self  = $class->SUPER::new( @_ );
  $self->parent($_[0]);
  $self->search( Wx::TextCtrl->new( $self, wxID_ANY, '', wxDefaultPosition, wxDefaultSize ) );
  $self->search->SetEditable(1);
  $self->lb_examples( Wx::ListCtrl->new( $self, wxID_ANY, wxDefaultPosition, wxDefaultSize,
                                      wxLC_REPORT|wxLC_HRULES|wxLC_VRULES ) );
  $self->lb_examples->InsertColumn(0, 'id',      wxLIST_FORMAT_LEFT, 35);
  $self->lb_examples->InsertColumn(1, 'example', wxLIST_FORMAT_LEFT, 200);

  $self->vbox(Wx::BoxSizer->new( wxVERTICAL ));
  $self->vbox->Add($self->search,      0, wxEXPAND|wxTOP|wxLEFT|wxRIGHT, 2);
  $self->vbox->Add($self->lb_examples, 2, wxEXPAND|wxTOP|wxLEFT|wxRIGHT, 2);
  # main
  $self->SetSizer( $self->vbox );
  $self->vbox->Fit( $self );

  EVT_LIST_ITEM_ACTIVATED($self, $self->lb_examples, \&OnSelect );

  $self
}

sub OnSelect {
  my ($self, $event) = @_;
  my $text = $self->lb_examples->GetItem($event->GetIndex,1)->GetText;
  $self->cb->(
    $self->lb_examples->GetItem($event->GetIndex,0)->GetText,
    $self->lb_examples->GetItem($event->GetIndex,1)->GetText
  ) if $self->cb;
  $self->Dismiss();
}

sub initialize_examples {
  my $self = shift;
  my @examples = $main::ioc->lookup('db')->get_all_examples(
    Dict::Learn::Dictionary->curr->{language_tr_id}{language_id}
  );
  $self->lb_examples->DeleteAllItems();
  for (@examples) {
    my $id = $self->lb_examples->InsertItem( Wx::ListItem->new );
    $self->lb_examples->SetItem($id, 0, $_->{example_id} );
    $self->lb_examples->SetItem($id, 1, $_->{example} );
  }
}

1;
