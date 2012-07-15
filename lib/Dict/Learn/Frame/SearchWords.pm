package Dict::Learn::Frame::SearchWords 0.1;

use Wx qw[:everything];
use Wx::Grid;
use Wx::Event qw[:everything];

use base 'Wx::Panel';

use Data::Printer;

use common::sense;

use Class::XSAccessor
  accessors => [ qw| parent
                     combobox listbox lb_item btn_lookup lookup_hbox
                     panel3_vbox listbox3_examples btn3_add_example
                     btn3_delete_example
                     btn3_edit panel3_hbox_btn
               | ];

sub new {
  my $class = shift;
  my $self  = $class->SUPER::new( splice @_ => 1 );
  $self->parent(shift);

  $self->panel3_vbox( Wx::BoxSizer->new( wxVERTICAL ) );
  $self->SetSizer( $self->panel3_vbox );

  $self->lookup_hbox( Wx::BoxSizer->new( wxHORIZONTAL ) );

  $self->combobox( Wx::ComboBox->new( $self, wxID_ANY, "", wxDefaultPosition, wxDefaultSize, [], 0, wxDefaultValidator  ) );

  $self->btn_lookup( Wx::Button->new( $self, -1, '#', [20, 20] ) );
  $self->lookup_hbox->Add($self->combobox, 1, wxTOP|wxGROW, 0);
  $self->lookup_hbox->Add($self->btn_lookup, 0);

  $self->listbox( Wx::ListCtrl->new( $self, wxID_ANY, wxDefaultPosition, wxDefaultSize, wxLC_REPORT|wxLC_HRULES|wxLC_VRULES ) );

  $self->listbox->InsertColumn( 0 , 'id',      wxLIST_FORMAT_LEFT, 35);
  $self->listbox->InsertColumn( 1 , 'Eng',     wxLIST_FORMAT_LEFT, 200);
  $self->listbox->InsertColumn( 2 , 'wc',      wxLIST_FORMAT_LEFT, 35);
  $self->listbox->InsertColumn( 3 , 'Ukr',     wxLIST_FORMAT_LEFT, 200);
  $self->listbox->InsertColumn( 4 , 'note',    wxLIST_FORMAT_LEFT, 200);
  $self->listbox->InsertColumn( 5 , 'created', wxLIST_FORMAT_LEFT, 150);

  $self->listbox3_examples( Wx::ListCtrl->new( $self, wxID_ANY, wxDefaultPosition, wxDefaultSize, wxLC_REPORT|wxLC_HRULES|wxLC_VRULES ) );
  $self->listbox3_examples->InsertColumn( 0, 'id',   wxLIST_FORMAT_LEFT, 35);
  $self->listbox3_examples->InsertColumn( 1, 'Eng',  wxLIST_FORMAT_LEFT, 200);
  $self->listbox3_examples->InsertColumn( 2, 'Ukr',  wxLIST_FORMAT_LEFT, 200);
  $self->listbox3_examples->InsertColumn( 3, 'Note', wxLIST_FORMAT_LEFT, 150);

  $self->panel3_hbox_btn( Wx::BoxSizer->new( wxHORIZONTAL ) );
  $self->btn3_add_example( Wx::Button->new( $self, -1, 'Add',     [-1, -1] ) );
  $self->btn3_edit( Wx::Button->new( $self, -1, 'Edit',    [-1, -1] ) );
  $self->btn3_delete_example( Wx::Button->new( $self, -1, 'Delete',  [-1, -1] ) );
  $self->panel3_hbox_btn->Add( $self->btn3_add_example    );
  $self->panel3_hbox_btn->Add( $self->btn3_edit   );
  $self->panel3_hbox_btn->Add( $self->btn3_delete_example );

  $self->panel3_vbox->Add( $self->lookup_hbox, 0, wxTOP|wxGROW, 5 );
  $self->panel3_vbox->Add( $self->listbox, 2, wxALL|wxGROW|wxEXPAND, 5 );
  $self->panel3_vbox->Add( $self->listbox3_examples, 1, wxALL|wxGROW|wxEXPAND, 5 );
  $self->panel3_vbox->Add( $self->panel3_hbox_btn, 0, wxALL|wxGROW|wxEXPAND, 5 );

  $self->Layout();
  $self->panel3_vbox->Fit( $self );

  # events
  EVT_TEXT(   $self, $self->combobox,            \&lookup         );
  EVT_BUTTON( $self, $self->btn_lookup,          \&lookup         );
  EVT_BUTTON( $self, $self->btn3_edit,           \&edit_item      );
  EVT_LIST_ITEM_SELECTED( $self, $self->listbox, \&load_examples  );

  $self->lookup;

  $self
}

sub lookup {
  my ( $self, $event ) = @_;
  $self->listbox->DeleteAllItems();
  for my $item ( $main::ioc->lookup('db')->find_items( $self->combobox->GetValue ) )
  {
    my $id = $self->listbox->InsertItem( Wx::ListItem->new );
    $self->listbox->SetItem($id, 0, $item->{word_id} );
    $self->listbox->SetItem($id, 1, $item->{word_orig} );
    $self->listbox->SetItem($id, 2, $item->{wordclass_abbr} );
    $self->listbox->SetItem($id, 3, $item->{word_tr} );
    $self->listbox->SetItem($id, 4, $item->{note} );
    $self->listbox->SetItem($id, 5, $item->{cdate} );
  }
}

sub edit_item {
  my $self = shift;
  my $curr_id = -1;
  my $panel1 = $self->parent->panel1;
  $panel1->clear_fields;
  $curr_id = $self->listbox->GetNextItem($curr_id, wxLIST_NEXT_ALL, wxLIST_STATE_SELECTED);
  $panel1->word_src->SetValue(  $self->listbox->GetItem($curr_id, 1)->GetText );
  $panel1->word_dst->SetValue(  $self->listbox->GetItem($curr_id, 3)->GetText );
  $panel1->word_note->SetValue( $self->listbox->GetItem($curr_id, 4)->GetText );
  my @examples;
  for (my $i = 0; $i < $self->listbox3_examples->GetItemCount; $i++) {
    my $id = $panel1->listbox_examples->InsertItem( Wx::ListItem->new );
    $panel1->listbox_examples->SetItem(
      $id, 0, $self->listbox3_examples->GetItem($i, 0)->GetText );
    $panel1->listbox_examples->SetItem(
      $id, 1, $self->listbox3_examples->GetItem($i, 1)->GetText );
    $panel1->listbox_examples->SetItem(
      $id, 2, $self->listbox3_examples->GetItem($i, 2)->GetText );
    $panel1->listbox_examples->SetItem(
      $id, 3, $self->listbox3_examples->GetItem($i, 3)->GetText );
  }

  $panel1->panel1_item_id( $self->listbox->GetItem($curr_id, 0)->GetText );

  $self->parent->notebook->SetPageText(
    0 => "Edit item id#".$panel1->panel1_item_id);
  $self->parent->notebook->ChangeSelection(0);

}

sub load_examples {
  my $self = shift;
  my $obj  = shift;
  my $id   = $obj->GetLabel();
  $self->listbox3_examples->DeleteAllItems();
  my @items = $main::ioc->lookup('db')->select_examples($id);
  for my $item (@items) {
    my $id = $self->listbox3_examples->InsertItem( Wx::ListItem->new );
    $self->listbox3_examples->SetItem($id, 0, $item->{example_id} );
    $self->listbox3_examples->SetItem($id, 1, $item->{sentence_orig} );
    $self->listbox3_examples->SetItem($id, 2, $item->{sentence_tr} );
    $self->listbox3_examples->SetItem($id, 3, $item->{note} );
  }
}

1;
