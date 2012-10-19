package Dict::Learn::Frame::PageAddItem 0.1;

use Wx qw[:everything];
use Wx::Grid;
use Wx::Event qw[:everything];

use base 'Wx::Panel';

use LWP::UserAgent;

# use lib qw[ ];

use Dict::Learn::Translate;

use common::sense;

use Data::Printer;

use Class::XSAccessor
  accessors => [ qw| parent
                     word_note example_note wordclass
                     word_src word_dst
                     text_src text_dst
                     listbox_examples
                     btn_translate_word
                     panel1_vbox panel1_hbox_words panel1_vbox_dst panel1_hbox_dst_item

                     panel1_hbox_examples panel1_hbox_btn

                     panel1_curr_example_id panel1_item_id
                     btn_add_word btn_add_example btn_clear btn_tran btn_save btn_delete_word
                     btn_delete_example
                     tran
                   | ];

sub new {
  my $class  = shift;
  my $self   = $class->SUPER::new( splice @_ => 1 );
  $self->tran( Dict::Learn::Translate->new() );
  $self->parent( shift );
  $self->panel1_vbox( Wx::BoxSizer->new( wxVERTICAL ) );
  $self->SetSizer( $self->panel1_vbox );
  $self->panel1_hbox_words( Wx::BoxSizer->new( wxHORIZONTAL ) );
  $self->panel1_hbox_examples( Wx::BoxSizer->new( wxHORIZONTAL ) );
  $self->panel1_hbox_btn( Wx::BoxSizer->new( wxHORIZONTAL ) );
  $self->word_src( Wx::TextCtrl->new( $self, -1, '', [-1,-1], [-1,-1] ) );
  $self->text_src( Wx::TextCtrl->new( $self, -1, '', [-1,-1], [-1,-1], wxTE_MULTILINE ) );
  $self->text_dst( Wx::TextCtrl->new( $self, -1, '', [-1,-1], [-1,-1], wxTE_MULTILINE ) );

  $self->btn_translate_word( Wx::Button->new( $self, -1, '<=>', [-1, -1] ));
  $self->panel1_hbox_words->Add( $self->word_src, 2, wxALL|wxTOP, 5 );
  $self->panel1_hbox_words->Add( $self->btn_translate_word, 1, wxTOP, 5 );

  $self->word_dst([]);
  $self->panel1_hbox_dst_item([]);

  $self->panel1_vbox_dst( Wx::BoxSizer->new( wxVERTICAL ));

  $self->add_dst_item;

  $self->panel1_hbox_words->Add( $self->panel1_vbox_dst, 4, wxALL|wxEXPAND, 5 );

  $self->panel1_hbox_examples->Add( $self->text_src , 1, wxALL|wxEXPAND, 5 );
  $self->panel1_hbox_examples->Add( $self->text_dst , 1, wxALL|wxEXPAND, 5 );
  $self->word_note( Wx::TextCtrl->new( $self, -1, '', [-1,-1], [-1,-1] ) );
  $self->example_note( Wx::TextCtrl->new( $self, -1, '', [-1,-1], [-1,-1] ) );
  $self->panel1_vbox->Add( $self->panel1_hbox_words ,  0, wxALL|wxGROW, 0 );
  $self->panel1_vbox->Add( $self->word_note, 0, wxALL|wxGROW, 5 );
  $self->panel1_vbox->Add( $self->panel1_hbox_examples , 1, wxALL|wxGROW,   0 );
  $self->panel1_vbox->Add( $self->example_note, 0, wxALL|wxGROW, 5 );
  $self->panel1_vbox->Add( $self->panel1_hbox_btn,  0, wxALL|wxGROW,   5 );
  $self->btn_save( Wx::Button->new( $self, -1, 'Save', [-1, -1] ));
  $self->btn_add_word( Wx::Button->new( $self, -1, 'Add/Save', [-1, -1] ));
  $self->btn_add_example( Wx::Button->new( $self, -1, 'Add Example', [-1, -1] ));
  $self->btn_tran( Wx::Button->new( $self, -1, 'Translate', [-1, -1] ));
  $self->btn_clear( Wx::Button->new( $self, -1, 'Clear',    [-1, -1] ));
  $self->btn_delete_word( Wx::Button->new( $self, -1, 'Delete word',    [-1, -1] ) );
  $self->btn_delete_example( Wx::Button->new( $self, -1, 'Delete example',    [-1, -1] ) );
  $self->panel1_hbox_btn->Add( $self->btn_add_word , 0, wxBOTTOM|wxALIGN_LEFT|wxLEFT, 5 );
  $self->panel1_hbox_btn->Add( $self->btn_add_example , 0, wxBOTTOM|wxALIGN_LEFT|wxLEFT, 5 );
  $self->panel1_hbox_btn->Add( $self->btn_tran , 0, wxBOTTOM|wxALIGN_LEFT|wxLEFT, 5 );
  $self->panel1_hbox_btn->Add( $self->btn_clear,  0, wxBOTTOM|wxALIGN_LEFT|wxLEFT, 5);
  $self->panel1_hbox_btn->Add( $self->btn_save,  0, wxBOTTOM|wxALIGN_LEFT|wxLEFT, 5);
  $self->panel1_hbox_btn->Add( $self->btn_delete_word ,  0, wxBOTTOM|wxALIGN_LEFT|wxLEFT, 5);
  $self->panel1_hbox_btn->Add( $self->btn_delete_example ,  0, wxBOTTOM|wxALIGN_LEFT|wxLEFT, 5);

  $self->listbox_examples( Wx::ListCtrl->new( $self, wxID_ANY, wxDefaultPosition, wxDefaultSize, wxLC_REPORT|wxLC_HRULES|wxLC_VRULES ) );
  $self->listbox_examples->InsertColumn( 0, 'id',   wxLIST_FORMAT_LEFT, 25);
  $self->listbox_examples->InsertColumn( 1, 'Eng',  wxLIST_FORMAT_LEFT, 300);
  $self->listbox_examples->InsertColumn( 2, 'Ukr',  wxLIST_FORMAT_LEFT, 300);
  $self->listbox_examples->InsertColumn( 3, 'Note', wxLIST_FORMAT_LEFT, 150);

  $self->panel1_curr_example_id(undef);

  # panel1_mode: undef - add, other - edit
  $self->panel1_item_id(undef);

  $self->panel1_vbox->Add( $self->listbox_examples, 1, wxALL|wxGROW|wxEXPAND, 5 );

  $self->Layout();
  $self->panel1_vbox->Fit( $self );

  # events
  EVT_BUTTON( $self, $self->btn_add_example,     \&add_example    );
  EVT_BUTTON( $self, $self->btn_add_word,        \&add_word       );
  EVT_BUTTON( $self, $self->btn_clear,           \&clear_fields   );
  EVT_BUTTON( $self, $self->btn_save,            \&example_save   );
  EVT_BUTTON( $self, $self->btn_delete_word,     \&delete_word    );
  EVT_BUTTON( $self, $self->btn_delete_example,  \&delete_example );
  EVT_BUTTON( $self, $self->btn_translate_word,  \&translate_word );

  EVT_LIST_ITEM_SELECTED( $self, $self->listbox_examples, \&load_example_inputs );

  $self
}

sub make_dst_item {
  my $self = shift;
  push @{ $self->panel1_hbox_dst_item } => Wx::BoxSizer->new( wxHORIZONTAL );
  my $id = $#{ $self->panel1_hbox_dst_item };
  $self->word_dst->[$id] = [
    Wx::ComboBox->new( $self, wxID_ANY, undef, wxDefaultPosition, wxDefaultSize, [ $self->import_wordclass ], wxCB_DROPDOWN|wxCB_READONLY, wxDefaultValidator  ),
    Wx::TextCtrl->new( $self, -1, '', [-1,-1], [-1,-1] ),
    Wx::Button->new( $self, -1, '+', [-1, -1] ),
    Wx::Button->new( $self, -1, '-', [-1, -1] )
  ];
  EVT_BUTTON( $self, $self->word_dst->[$id][2], \&add_dst_item );
  EVT_BUTTON( $self, $self->word_dst->[$id][3], sub { $self->del_dst_item($id); } );
  $self->word_dst->[$id][0]->SetSelection(0);
  $self->panel1_hbox_dst_item->[$id]->Add($self->word_dst->[$id]->[0], 2, wxALL|wxTOP, 0);
  $self->panel1_hbox_dst_item->[$id]->Add($self->word_dst->[$id]->[1], 4, wxALL|wxEXPAND, 0);
  $self->panel1_hbox_dst_item->[$id]->Add($self->word_dst->[$id]->[2], 1, wxALL|wxTOP, 0);
  $self->panel1_hbox_dst_item->[$id]->Add($self->word_dst->[$id]->[3], 1, wxALL|wxTOP, 0);
  $self->panel1_hbox_dst_item->[$id]
}

sub add_dst_item {
  my $self = shift;
  $self->panel1_vbox_dst->Add( $self->make_dst_item, 1, wxALL|wxGROW, 0 );
  $self->Layout();
  $self
}

sub del_dst_item {
  my $self = shift;
  my $id = shift;
  $self->panel1_vbox_dst->Remove($self->panel1_hbox_dst_item->[$id]);
  my $i=0;
  for ( 0 .. $#{ $self->word_dst->[$id] } ) {
    $self->word_dst->[$id][$_]->Destroy();
    delete $self->word_dst->[$id][$_];
  }
  p($self->word_dst);
  $self->Layout();
  print "$id\n";
  $self
}

sub add_word {
  my $self = shift;
  my @examples;
  if ($self->listbox_examples->GetItemCount > 0) {
    for (my $i = 0; $i < $self->listbox_examples->GetItemCount; $i++) {
      push @examples  => {
        sentence_orig => $self->listbox_examples->GetItem($i, 1)->GetText,
        sentence_tr   => $self->listbox_examples->GetItem($i, 2)->GetText,
        note          => $self->listbox_examples->GetItem($i, 3)->GetText,
        example_id    => $self->listbox_examples->GetItem($i, 0)->GetText ||
                         undef,
      };
    }
  } elsif ($self->text_src->GetValue and
           $self->text_src->GetValue !~ /^\s+$/)
  {
    push @examples  => {
      sentence_orig => $self->text_src->GetValue(),
      sentence_tr   => $self->text_dst->GetValue(),
      note          => $self->example_note->GetValue(),
    };
  }

  for my $word_dst_item ( @{ $self->word_dst } ) {
    my @params = (
        word_orig    => $self->word_src->GetValue(),
        word_tr      => $word_dst_item->[1]->GetValue(),
        note         => $self->word_note->GetValue(),
        wordclass_id => int($word_dst_item->[0]->GetSelection()),
        examples     => [ @examples ]
    );

    if (defined $self->panel1_item_id and
                $self->panel1_item_id >= 0)
    {
      push @params, word_id => $self->panel1_item_id;
      $main::ioc->lookup('db')->update_item(@params);
      last;
    } else {
      $main::ioc->lookup('db')->add_word(@params);
    }
  }

  $self->clear_fields;
  $self->parent->notebook->SetPageText(0 => "Add item");
  $self
}

sub add_example {
  my $self = shift;
  my $id = $self->listbox_examples->InsertItem( Wx::ListItem->new );
  $self->listbox_examples->SetItem($id, 1, $self->text_src->GetValue() );
  $self->listbox_examples->SetItem($id, 2, $self->text_dst->GetValue() );
  $self->listbox_examples->SetItem($id, 3, $self->example_note->GetValue() );
  $self->clear_example_inputs;
  $self
}

sub clear_example_inputs {
  my $self = shift;
  $self->text_src->Clear;
  $self->text_dst->Clear;
  $self->example_note->Clear;

  $self->panel1_curr_example_id(undef);

  $self
}

sub example_save {
  my $self = shift;

  unless (defined $self->panel1_curr_example_id) {
    warn "can't save";
    return
  }

  $self->listbox_examples->SetItem( $self->panel1_curr_example_id, 1,
                                    $self->text_src->GetValue() );
  $self->listbox_examples->SetItem( $self->panel1_curr_example_id, 2,
                                    $self->text_dst->GetValue() );
  $self->listbox_examples->SetItem( $self->panel1_curr_example_id, 3,
                                    $self->example_note->GetValue() );

  $self->clear_example_inputs;

  $self
}

sub import_wordclass {
  my $self = shift;
  map { $_->{name_orig} } $main::ioc->lookup('db')->select_wordclass();
}

sub clear_fields {
  my $self = shift;
  $self->word_src->Clear;
  for my $word_dst_item ( @{ $self->word_dst } ) {
    $word_dst_item->[0]->SetSelection(0);
    $word_dst_item->[1]->Clear;
  }
  $self->word_note->Clear;
  $self->text_src->Clear;
  $self->text_dst->Clear;
  $self->example_note->Clear;
  $self->listbox_examples->DeleteAllItems;
  $self->panel1_curr_example_id(undef);
  $self->panel1_item_id(undef);
}

sub load_example_inputs {
  my $self = shift;
  my $item = shift;
  $self->clear_example_inputs;
  $self->panel1_curr_example_id($item->GetIndex());
  $self->text_src->SetValue($self->listbox_examples->GetItem($item->GetIndex(), 1)->GetText);
  $self->text_dst->SetValue($self->listbox_examples->GetItem($item->GetIndex(), 2)->GetText);
  $self->example_note->SetValue($self->listbox_examples->GetItem($item->GetIndex(), 3)->GetText);
  $self
}

sub load_word {
  my $self   = shift;
  my %params = @_;
  $self->clear_fields;
  $self->word_src->SetValue($params{word_src});
  $self->word_dst->[0][1]->SetValue($params{word_dst});
  $self->word_note->SetValue($params{word_note});
  for my $example_item ( @{ $params{examples} } ) {
    my $id = $self->listbox_examples->InsertItem( Wx::ListItem->new );
    $self->listbox_examples->SetItem(
      $id, 0, $example_item->[0] );
    $self->listbox_examples->SetItem(
      $id, 1, $example_item->[1] );
    $self->listbox_examples->SetItem(
      $id, 2, $example_item->[2] );
    $self->listbox_examples->SetItem(
      $id, 3, $example_item->[3] );
  }
  $self->panel1_item_id( $params{word_id} );
  $self->parent->notebook->SetPageText(
    0 => "Edit item id#".$self->panel1_item_id);
}

sub dst_count { scalar @{ $_[0]->word_dst } }

sub get_partofspeach_index {
  my $self = shift;
  my $name = shift;
  for ($main::ioc->lookup('db')->select_wordclass( name => $name ))
    { return $_->{wordclass_id} }
}

sub translate_word {
  my $self = shift;
  my $res = $self->tran->using('Google')->do(
    'en' => 'uk',
    $self->word_src->GetValue()
  );
  p($res);
  my $limit = $self->dst_count;
  if (keys %$res > 1) {
    my $i = 0;
    for my $partofspeach ( keys %$res ) {
      next if $partofspeach eq '_';
      $self->add_dst_item if $i >= $limit;
      $self->word_dst->[$i][0]->SetSelection(
        $self->get_partofspeach_index($partofspeach)
      );
      $self->word_dst->[$i][1]->SetValue( join ' | ' =>
        map { ref $_ eq 'ARRAY' ? $_->[0] : $_ } @{$res->{$partofspeach}}
      );
      $i++;
    }
  }
  else {
    $self->word_dst->[0][1]->SetValue( $res->{_} );
  }
}

1;
