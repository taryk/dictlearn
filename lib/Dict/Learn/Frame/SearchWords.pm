package Dict::Learn::Frame::SearchWords 0.1;

use Wx qw[:everything];
use Wx::Grid;
use Wx::Event qw[:everything];

use base 'Wx::Panel';

use Dict::Learn::Dictionary;
use Data::Printer;

use common::sense;

use constant {
  COL_LANG1 => 1,
  COL_LANG2 => 3,
  COL_E_LANG1 => 1,
  COL_E_LANG2 => 2,
};

use Class::XSAccessor
  accessors => [ qw| parent
                     vbox combobox btn_lookup lookup_hbox
                     hbox_words lb_words
                     hbox_examples lb_examples
                     vbox_btn_words
                     btn_edit_word btn_delete_word btn_unlink_word
                     vbox_btn_examples
                     btn_add_example btn_delete_example
                     btn_edit_example btn_unlink_example
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

  ### words

  # buttons
  $self->btn_edit_word(   Wx::Button->new( $self, -1, 'Edit',   [-1, -1] ) );
  $self->btn_unlink_word( Wx::Button->new( $self, -1, 'Unlink', [-1, -1] ) );
  $self->btn_delete_word( Wx::Button->new( $self, -1, 'Del',    [-1, -1] ) );
  # layout
  $self->vbox_btn_words( Wx::BoxSizer->new( wxVERTICAL ) );
  $self->vbox_btn_words->Add( $self->btn_edit_word   );
  $self->vbox_btn_words->Add( $self->btn_unlink_word );
  $self->vbox_btn_words->Add( $self->btn_delete_word );

  # table
  $self->lb_words( Wx::ListCtrl->new( $self, wxID_ANY, wxDefaultPosition, wxDefaultSize, wxLC_REPORT|wxLC_HRULES|wxLC_VRULES ) );
  $self->lb_words->InsertColumn( 0          , 'id',      wxLIST_FORMAT_LEFT, 35);
  $self->lb_words->InsertColumn( COL_LANG1  , 'Eng',     wxLIST_FORMAT_LEFT, 200);
  $self->lb_words->InsertColumn( 2          , 'wc',      wxLIST_FORMAT_LEFT, 35);
  $self->lb_words->InsertColumn( COL_LANG2  , 'Ukr',     wxLIST_FORMAT_LEFT, 200);
  $self->lb_words->InsertColumn( 4          , 'note',    wxLIST_FORMAT_LEFT, 200);
  $self->lb_words->InsertColumn( 5          , 'created', wxLIST_FORMAT_LEFT, 150);
  # layout
  $self->hbox_words( Wx::BoxSizer->new( wxHORIZONTAL ) );
  $self->hbox_words->Add( $self->vbox_btn_words, 0, wxRIGHT, 5 );
  $self->hbox_words->Add( $self->lb_words, 2, wxALL|wxGROW|wxEXPAND, 0 );

  ### examples

  # buttons
  $self->btn_add_example(    Wx::Button->new( $self, -1, 'Add',    [-1, -1] ) );
  $self->btn_edit_example(   Wx::Button->new( $self, -1, 'Edit',   [-1, -1] ) );
  $self->btn_unlink_example( Wx::Button->new( $self, -1, 'Unlink', [-1, -1] ) );
  $self->btn_delete_example( Wx::Button->new( $self, -1, 'Del',    [-1, -1] ) );
  # layout
  $self->vbox_btn_examples( Wx::BoxSizer->new( wxVERTICAL ));
  $self->vbox_btn_examples->Add( $self->btn_add_example    );
  $self->vbox_btn_examples->Add( $self->btn_edit_example   );
  $self->vbox_btn_examples->Add( $self->btn_unlink_example );
  $self->vbox_btn_examples->Add( $self->btn_delete_example );

  # table
  $self->lb_examples( Wx::ListCtrl->new( $self, wxID_ANY, wxDefaultPosition, wxDefaultSize, wxLC_REPORT|wxLC_HRULES|wxLC_VRULES ) );
  $self->lb_examples->InsertColumn( 0, 'id',   wxLIST_FORMAT_LEFT, 35);
  $self->lb_examples->InsertColumn( COL_E_LANG1, 'Eng',  wxLIST_FORMAT_LEFT, 200);
  $self->lb_examples->InsertColumn( COL_E_LANG2, 'Ukr',  wxLIST_FORMAT_LEFT, 200);
  $self->lb_examples->InsertColumn( 3, 'Note', wxLIST_FORMAT_LEFT, 150);
  # layout
  $self->hbox_examples( Wx::BoxSizer->new( wxHORIZONTAL ) );
  $self->hbox_examples->Add( $self->vbox_btn_examples, 0, wxRIGHT, 5 );
  $self->hbox_examples->Add( $self->lb_examples, 2, wxALL|wxGROW|wxEXPAND, 0 );

  ### main layout
  $self->vbox( Wx::BoxSizer->new( wxVERTICAL ) );
  $self->vbox->Add( $self->lookup_hbox, 0, wxTOP|wxGROW, 5 );
  $self->vbox->Add( $self->hbox_words, 2, wxALL|wxGROW|wxEXPAND, 0 );
  $self->vbox->Add( $self->hbox_examples, 1, wxALL|wxGROW|wxEXPAND, 0 );
  $self->SetSizer( $self->vbox );
  $self->Layout();
  $self->vbox->Fit( $self );

  # events
  EVT_TEXT(   $self, $self->combobox,             \&lookup         );
  EVT_BUTTON( $self, $self->btn_lookup,           \&lookup         );
  EVT_BUTTON( $self, $self->btn_edit_word,        \&edit_word      );
  EVT_BUTTON( $self, $self->btn_unlink_word,      \&unlink_word    );
  EVT_BUTTON( $self, $self->btn_delete_word,      \&delete_word    );
  EVT_BUTTON( $self, $self->btn_add_example,      \&add_example    );
  EVT_BUTTON( $self, $self->btn_edit_example,     \&edit_example   );
  EVT_BUTTON( $self, $self->btn_unlink_example,   \&unlink_example );
  EVT_BUTTON( $self, $self->btn_delete_example,   \&delete_example );
  EVT_LIST_ITEM_SELECTED( $self, $self->lb_words, \&load_examples  );

  # $self->lookup;
  Dict::Learn::Dictionary->cb(sub {
    my $dict = shift;
    my @li = ( Wx::ListItem->new, Wx::ListItem->new );
    $li[0]->SetText( $dict->curr->{language_orig_id}{language_name} );
    $li[1]->SetText( $dict->curr->{language_tr_id}{language_name} );
    $self->lb_words->SetColumn( COL_LANG1, $li[0] );
    $self->lb_words->SetColumn( COL_LANG2, $li[1] );
    $self->lb_examples->SetColumn( COL_E_LANG1, $li[0] );
    $self->lb_examples->SetColumn( COL_E_LANG2, $li[1] );
    $self->lookup;
  });

  $self
}

sub lookup {
  my ($self, $event) = @_;
  $self->lb_words->DeleteAllItems();
  for my $item ($main::ioc->lookup('db')->find_items(
    word    => $self->combobox->GetValue,
    lang_id => Dict::Learn::Dictionary->curr->{language_orig_id}{language_id} ))
  {
    my $id = $self->lb_words->InsertItem( Wx::ListItem->new );
    my $word = $item->{is_irregular} ?
      join(' / ' => $item->{word_orig}, $item->{word2}, $item->{word3}) :
      $item->{word_orig};
    $self->lb_words->SetItem($id, 0,         $item->{word_id}   );
    $self->lb_words->SetItem($id, COL_LANG1, $word              );
    $self->lb_words->SetItem($id, 2,         $item->{wordclass} );
    $self->lb_words->SetItem($id, COL_LANG2, $item->{word_tr}   );
    $self->lb_words->SetItem($id, 4,         $item->{note}      );
    $self->lb_words->SetItem($id, 5,         $item->{cdate}     );
  }
}

sub edit_word {
  my $self = shift;
  my $curr_id = $self->lb_words->GetNextItem(
    -1, wxLIST_NEXT_ALL, wxLIST_STATE_SELECTED
  );

  $self->parent->p_addword->load_word(
    word_id => $self->get_word_id($curr_id),
  );

  $self->parent->notebook->ChangeSelection(1);
}

sub edit_example {
  my $self = shift;
  my $curr_id = $self->lb_examples->GetNextItem(
    -1, wxLIST_NEXT_ALL, wxLIST_STATE_SELECTED
  );

  $self->parent->p_addexample->load_example(
    example_id => $self->get_example_id($curr_id),
  );

  $self->parent->notebook->ChangeSelection(2);
}

sub load_examples {
  my $self = shift;
  my $obj  = shift;
  my $id   = $obj->GetLabel();
  $self->lb_examples->DeleteAllItems();
  my @items = $main::ioc->lookup('db')->select_examples(
    word_id       => $id,
    dictionary_id => Dict::Learn::Dictionary->curr_id,
  );
  for my $item (@items) {
    my $id = $self->lb_examples->InsertItem( Wx::ListItem->new );
    $self->lb_examples->SetItem($id, 0,           $item->{example_id}   );
    $self->lb_examples->SetItem($id, COL_E_LANG1, $item->{example_orig} );
    $self->lb_examples->SetItem($id, COL_E_LANG2, $item->{example_tr}   );
    $self->lb_examples->SetItem($id, 3,           $item->{note}         );
  }
}

sub get_word_id {
  my ($self, $rowid) = @_;
  $self->lb_words->GetItem($rowid, 0)->GetText
}

sub get_example_id {
  my ($self, $rowid) = @_;
  $self->lb_examples->GetItem($rowid, 0)->GetText
}

sub delete_word {
  my $self = shift;
  my $curr_id = $self->lb_words->GetNextItem(
    -1, wxLIST_NEXT_ALL, wxLIST_STATE_SELECTED
  );
  $main::ioc->lookup('db')->delete_word(
    $self->get_word_id($curr_id)
  );
  $self->lookup;
}

sub unlink_word {
  my $self = shift;
  my $curr_id = $self->lb_words->GetNextItem(
    -1, wxLIST_NEXT_ALL, wxLIST_STATE_SELECTED
  );
  $main::ioc->lookup('db')->unlink_word(
    $self->get_word_id($curr_id)
  );
  $self->lookup;
}

sub delete_example {
  my $self = shift;
  my $curr_id = $self->lb_examples->GetNextItem(
    -1, wxLIST_NEXT_ALL, wxLIST_STATE_SELECTED
  );
  $main::ioc->lookup('db')->delete_example(
    $self->get_example_id($curr_id)
  );
  $self->lookup;
}

sub unlink_example {
  my $self = shift;
  my $curr_id = $self->lb_examples->GetNextItem(
    -1, wxLIST_NEXT_ALL, wxLIST_STATE_SELECTED
  );
  $main::ioc->lookup('db')->unlink_example(
    $self->get_example_id($curr_id)
  );
  $self->lookup;
}

1;
