package Dict::Learn::Frame::AddExample 0.1;

use Wx qw[:everything];
use Wx::Grid;
use Wx::Event qw[:everything];

use base 'Wx::Panel';

use LWP::UserAgent;

# use lib qw[ ];

use Dict::Learn::Translate;

use common::sense;

use Data::Printer;

use Scalar::Util qw[ weaken ];

use Class::XSAccessor
  accessors => [ qw| parent
                     text_src text_dst example_note
                     btn_translate
                     vbox vbox_src vbox_dst hbox_dst_item

                     hbox_examples hbox_btn

                     search_words linked_words
                     curr_example_id item_id
                     btn_add btn_clear btn_translate
                     tran
                   | ];

sub new {
  my $class  = shift;
  my $self   = $class->SUPER::new( splice @_ => 1 );
  $self->tran( Dict::Learn::Translate->new() );
  $self->parent( shift );

  ### src
  $self->text_src( Wx::TextCtrl->new( $self, -1, '', [-1,-1], [-1,-1], wxTE_MULTILINE ) );
  $self->example_note( Wx::TextCtrl->new( $self, -1, '', [-1,-1], [-1,-1] ) );
  $self->search_words( Wx::ComboBox->new( $self, wxID_ANY, undef, wxDefaultPosition, wxDefaultSize, [  ], wxCB_DROPDOWN, wxDefaultValidator ) );
  $self->linked_words( Wx::CheckListBox->new( $self, wxID_ANY, wxDefaultPosition, wxDefaultSize, [], 0, wxDefaultValidator ) );
  # layout
  $self->vbox_src( Wx::BoxSizer->new( wxVERTICAL ));
  $self->vbox_src->Add( $self->text_src, 3, wxALL|wxEXPAND, 5 );
  $self->vbox_src->Add( $self->example_note, 0, wxALL|wxGROW, 5 );
  $self->vbox_src->Add( $self->search_words, 0, wxALL|wxGROW, 5 );
  $self->vbox_src->Add( $self->linked_words, 3, wxALL|wxEXPAND, 5 );
  # initialisation
  $self->load_words;

  ### dst
  $self->text_dst([]);
  # layout
  $self->vbox_dst( Wx::BoxSizer->new( wxVERTICAL ) );
  $self->hbox_dst_item([]);
  $self->add_dst_item;

  ### hbox_examples layout
  $self->hbox_examples( Wx::BoxSizer->new( wxHORIZONTAL ) );
  $self->hbox_examples->Add( $self->vbox_src, 2, wxALL|wxEXPAND, 0 );
  $self->hbox_examples->Add( $self->vbox_dst, 3, wxALL|wxEXPAND, 0 );

  ### btn
  $self->btn_add( Wx::Button->new( $self, -1, 'Add Example', [-1, -1] ));
  $self->btn_translate( Wx::Button->new( $self, -1, 'Translate', [-1, -1] ));
  $self->btn_clear( Wx::Button->new( $self, -1, 'Clear',    [-1, -1] ));
  # layout
  $self->hbox_btn( Wx::BoxSizer->new( wxHORIZONTAL ) );
  $self->hbox_btn->Add( $self->btn_add, 0, wxBOTTOM|wxALIGN_LEFT|wxLEFT, 5 );
  $self->hbox_btn->Add( $self->btn_translate, 0, wxBOTTOM|wxALIGN_LEFT|wxLEFT, 5 );
  $self->hbox_btn->Add( $self->btn_clear,  0, wxBOTTOM|wxALIGN_LEFT|wxLEFT, 5);


  ### main layout
  $self->vbox( Wx::BoxSizer->new( wxVERTICAL ) );
  $self->vbox->Add( $self->hbox_examples, 1, wxALL|wxGROW,   0 );
  $self->vbox->Add( $self->hbox_btn,  0, wxALL|wxGROW,   0 );
  $self->SetSizer( $self->vbox );
  $self->Layout();
  $self->vbox->Fit( $self );

  # mode: undef - add, other - edit
  $self->item_id(undef);
  $self->curr_example_id(undef);

  # events
  EVT_BUTTON( $self, $self->btn_add,             \&add          );
  EVT_BUTTON( $self, $self->btn_clear,           \&clear_fields );
  EVT_BUTTON( $self, $self->btn_translate,       \&translate    );

  $self
}

sub make_dst_item {
  my $self = shift;
  push @{ $self->hbox_dst_item } => Wx::BoxSizer->new( wxHORIZONTAL );
  my $id = $#{ $self->hbox_dst_item };
  $self->text_dst->[$id] = {
    id   => $id,
    text => Wx::TextCtrl->new( $self, -1, '', [-1,-1], [-1,-1], wxTE_MULTILINE ),
    vbox => Wx::BoxSizer->new( wxVERTICAL ),
    btnm => Wx::Button->new( $self, -1, '-', [-1, -1] ),
    btnp => Wx::Button->new( $self, -1, '+', [-1, -1] ),
    parent_hbox => $self->hbox_dst_item->[$id],
  };
  EVT_BUTTON( $self, $self->text_dst->[$id]{btnp}, \&add_dst_item );
  EVT_BUTTON( $self, $self->text_dst->[$id]{btnm}, sub { $self->del_dst_item($id); } );
  # $self->text_dst->[$id]{text}->SetSelection(0);
  $self->hbox_dst_item->[$id]->Add($self->text_dst->[$id]{text}, 4, wxALL|wxEXPAND, 0);
  $self->hbox_dst_item->[$id]->Add($self->text_dst->[$id]{vbox}, 1, wxALL|wxBOTTOM, 0);
  $self->text_dst->[$id]{vbox}->Add($self->text_dst->[$id]{btnm}, 1, wxALL|wxBOTTOM, 0);
  $self->text_dst->[$id]{vbox}->Add($self->text_dst->[$id]{btnp}, 1, wxALL|wxBOTTOM, 0);
  $self->text_dst->[$id]
}

sub add_dst_item {
  my $self = shift;
  my $el = $self->make_dst_item;
  $self->vbox_dst->Add( $el->{parent_hbox}, 1, wxALL|wxGROW, 5 );
  $self->Layout();
  $el
}

sub del_dst_item {
  my $self = shift;
  my $id = shift;
  $self->text_dst->[$id]{vbox}->Remove($self->text_dst->[$id]{btnm});
  $self->text_dst->[$id]{vbox}->Remove($self->text_dst->[$id]{btnp});
  for (qw[ text btnm btnp ]) {
    $self->text_dst->[$id]{$_}->Destroy();
    delete $self->text_dst->[$id]{$_};
  }
  $self->text_dst->[$id]{vbox}->Destroy();
  delete $self->text_dst->[$id]{vbox};
  $self->vbox_dst->Detach($self->hbox_dst_item->[$id])
    if defined $self->hbox_dst_item->[$id];
  $self->Layout();
  # weaken $self->hbox_dst_item->[$id];
  delete $self->hbox_dst_item->[$id];
  delete $self->text_dst->[$id];
  # $self->hbox_dst_item->[$id]->Destroy();
  $self
}

sub add {
  my $self = shift;
  return unless $self->text_src->GetValue or
                $self->text_src->GetValue !~ /^\s+$/;
  my %params = (
    text    => $self->text_src->GetValue(),
    note    => $self->example_note->GetValue(),
    lang_id => $self->parent->dictionary->{language_orig_id}{language_id},
  );
  if (defined(my $index = $self->linked_words->GetSelection()))
  {
    my $sel_word_id = $self->linked_words->GetClientData(
      $self->linked_words->GetSelection()
    );
    $params{word} = [ $sel_word_id ]
      if defined $sel_word_id and
                 $sel_word_id >= 0;
  }
  for my $text_dst_item ( grep { defined } @{ $self->text_dst } ) {
    next unless $text_dst_item->{text}->GetValue or
                $text_dst_item->{text}->GetValue !~ /^\s+$/;
    push @{ $params{translate} } => {
      text    => $text_dst_item->{text}->GetValue,
      lang_id => $self->parent->dictionary->{language_tr_id}{language_id},
    };
  }

  if (defined $self->item_id and
              $self->item_id >= 0)
  {
    $params{example_id} = $self->example_id;
    $main::ioc->lookup('db')->update_example(%params);
    $self->parent->notebook->SetPageText(2 => "Example");
  } else {
    $main::ioc->lookup('db')->add_example(%params);
  }

  $self->clear_fields;
  $self
}

sub clear_fields {
  my $self = shift;
  $self->text_src->Clear;
  for my $text_dst_item ( @{ $self->text_dst } ) {
    $text_dst_item->{text}->Clear;
  }
  $self->text_src->Clear;
  $self->example_note->Clear;
  $self->curr_example_id(undef);
  $self->item_id(undef);
}

# sub load_example_inputs {
#   my $self = shift;
#   my $item = shift;
#   $self->clear_example_inputs;
#   $self->curr_example_id($item->GetIndex());
#   $self->text_src->SetValue($self->listbox_examples->GetItem($item->GetIndex(), 1)->GetText);
#   $self->text_dst->SetValue($self->listbox_examples->GetItem($item->GetIndex(), 2)->GetText);
#   $self->example_note->SetValue($self->listbox_examples->GetItem($item->GetIndex(), 3)->GetText);
#   $self
# }

sub remove_all_dst {
  my $self = shift;
  for ( @{ $self->text_dst } ) {
    $self->del_dst_item($_->{id});
  }
}

sub load_example {
  my $self   = shift;
  my %params = @_;
  $self->clear_fields;
  $self->remove_all_dst;
  $self->curr_example_id( $params{example_id} );
  $self->text_src->SetValue( $params{text} );
  for my $text_tr ( @{ $params{translate} } ) {
    my $el = $self->add_dst_item;
    $el->{text}->SetValue($text_tr);
  }
  $self->parent->notebook->SetPageText(
    2 => "Edit example id#".$self->curr_example_id);
}

sub load_words {
  my $self = shift;
  $self->linked_words->Clear;
  for my $item ( $main::ioc->lookup('db')->select_words(
    $self->parent->dictionary->{language_orig_id}{language_id} ))
  {
    $self->linked_words->Append($item->{word}." (".$item->{wordclass}.")", $item->{id});
  }
}

sub dst_count { scalar @{ $_[0]->text_dst } }

sub translate {
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
