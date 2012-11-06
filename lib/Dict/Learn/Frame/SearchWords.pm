package Dict::Learn::Frame::SearchWords 0.1;

use Wx qw[:everything];
use Wx::Grid;
use Wx::Event qw[:everything];

use base 'Wx::Panel';

use Data::Printer;

use common::sense;

use Class::XSAccessor
  accessors => [ qw| parent
                     combobox lb_words btn_lookup lookup_hbox
                     vbox lb_examples btn_add_example
                     btn_delete_example
                     btn_edit hbox_btn
               | ];

sub new {
  my $class = shift;
  my $self  = $class->SUPER::new( splice @_ => 1 );
  $self->parent(shift);

  ### lookup
  $self->combobox( Wx::ComboBox->new( $self, wxID_ANY, "", wxDefaultPosition, wxDefaultSize, [], 0, wxDefaultValidator  ) );
  $self->btn_lookup( Wx::Button->new( $self, -1, '#', [20, 20] ) );
  # layout
  $self->lookup_hbox( Wx::BoxSizer->new( wxHORIZONTAL ) );
  $self->lookup_hbox->Add($self->combobox, 1, wxTOP|wxGROW, 0);
  $self->lookup_hbox->Add($self->btn_lookup, 0);

  ### words table
  $self->lb_words( Wx::ListCtrl->new( $self, wxID_ANY, wxDefaultPosition, wxDefaultSize, wxLC_REPORT|wxLC_HRULES|wxLC_VRULES ) );
  $self->lb_words->InsertColumn( 0 , 'id',      wxLIST_FORMAT_LEFT, 35);
  $self->lb_words->InsertColumn( 1 , 'Eng',     wxLIST_FORMAT_LEFT, 200);
  $self->lb_words->InsertColumn( 2 , 'wc',      wxLIST_FORMAT_LEFT, 35);
  $self->lb_words->InsertColumn( 3 , 'Ukr',     wxLIST_FORMAT_LEFT, 200);
  $self->lb_words->InsertColumn( 4 , 'note',    wxLIST_FORMAT_LEFT, 200);
  $self->lb_words->InsertColumn( 5 , 'created', wxLIST_FORMAT_LEFT, 150);

  ### examples table
  $self->lb_examples( Wx::ListCtrl->new( $self, wxID_ANY, wxDefaultPosition, wxDefaultSize, wxLC_REPORT|wxLC_HRULES|wxLC_VRULES ) );
  $self->lb_examples->InsertColumn( 0, 'id',   wxLIST_FORMAT_LEFT, 35);
  $self->lb_examples->InsertColumn( 1, 'Eng',  wxLIST_FORMAT_LEFT, 200);
  $self->lb_examples->InsertColumn( 2, 'Ukr',  wxLIST_FORMAT_LEFT, 200);
  $self->lb_examples->InsertColumn( 3, 'Note', wxLIST_FORMAT_LEFT, 150);

  ### buttons
  $self->btn_add_example( Wx::Button->new( $self, -1, 'Add',     [-1, -1] ) );
  $self->btn_edit( Wx::Button->new( $self, -1, 'Edit',    [-1, -1] ) );
  $self->btn_delete_example( Wx::Button->new( $self, -1, 'Delete',  [-1, -1] ) );

  # layout
  $self->hbox_btn( Wx::BoxSizer->new( wxHORIZONTAL ) );
  $self->hbox_btn->Add( $self->btn_add_example );
  $self->hbox_btn->Add( $self->btn_edit );
  $self->hbox_btn->Add( $self->btn_delete_example );

  ### main layout
  $self->vbox( Wx::BoxSizer->new( wxVERTICAL ) );
  $self->vbox->Add( $self->lookup_hbox, 0, wxTOP|wxGROW, 5 );
  $self->vbox->Add( $self->lb_words, 2, wxALL|wxGROW|wxEXPAND, 5 );
  $self->vbox->Add( $self->lb_examples, 1, wxALL|wxGROW|wxEXPAND, 5 );
  $self->vbox->Add( $self->hbox_btn, 0, wxALL|wxGROW|wxEXPAND, 5 );
  $self->SetSizer( $self->vbox );
  $self->Layout();
  $self->vbox->Fit( $self );

  # events
  EVT_TEXT(   $self, $self->combobox,            \&lookup         );
  EVT_BUTTON( $self, $self->btn_lookup,          \&lookup         );
  EVT_BUTTON( $self, $self->btn_edit,            \&edit_item      );
  EVT_LIST_ITEM_SELECTED( $self, $self->lb_words, \&load_examples  );

  $self->lookup;

  $self
}

sub lookup {
  my ( $self, $event ) = @_;
  $self->lb_words->DeleteAllItems();
  for my $item ( $main::ioc->lookup('db')->find_items( $self->combobox->GetValue ) )
  {
    my $id = $self->lb_words->InsertItem( Wx::ListItem->new );
    $self->lb_words->SetItem($id, 0, $item->{word_id} );
    $self->lb_words->SetItem($id, 1, $item->{word_orig} );
    $self->lb_words->SetItem($id, 2, $item->{wordclass} );
    $self->lb_words->SetItem($id, 3, $item->{word_tr} );
    $self->lb_words->SetItem($id, 4, $item->{note} );
    $self->lb_words->SetItem($id, 5, $item->{cdate} );
  }
}

sub edit_item {
  my $self = shift;
  my $curr_id = -1;
  my $panel1 = $self->parent->panel1;

  $curr_id = $self->lb_words->GetNextItem($curr_id, wxLIST_NEXT_ALL, wxLIST_STATE_SELECTED);

  my @examples;
  for my $i (0 .. $self->lb_examples->GetItemCount - 1) {
    push @examples => [
      $self->lb_examples->GetItem($i, 0)->GetText,
      $self->lb_examples->GetItem($i, 1)->GetText,
      $self->lb_examples->GetItem($i, 2)->GetText,
      $self->lb_examples->GetItem($i, 3)->GetText
    ];
  }

  $panel1->load_word(
    word_id   => $self->lb_words->GetItem($curr_id, 0)->GetText,
    word_src  => $self->lb_words->GetItem($curr_id, 1)->GetText,
    word_dst  => $self->lb_words->GetItem($curr_id, 3)->GetText,
    word_note => $self->lb_words->GetItem($curr_id, 4)->GetText,
    examples  => \@examples
  );

  $self->parent->notebook->ChangeSelection(0);
}

sub load_examples {
  my $self = shift;
  my $obj  = shift;
  my $id   = $obj->GetLabel();
  $self->lb_examples->DeleteAllItems();
  my @items = $main::ioc->lookup('db')->select_examples($id);
  for my $item (@items) {
    my $id = $self->lb_examples->InsertItem( Wx::ListItem->new );
    $self->lb_examples->SetItem($id, 0, $item->{example1_id}{example_id} );
    $self->lb_examples->SetItem($id, 1, $item->{example1_id}{example} );
    $self->lb_examples->SetItem($id, 2, $item->{example2_id}{example} );
    $self->lb_examples->SetItem($id, 3, $item->{rel_examples}{note} );
  }
}

1;
