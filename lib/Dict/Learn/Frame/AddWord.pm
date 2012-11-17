package Dict::Learn::Frame::AddWord 0.1;

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
                     word_note wordclass
                     word_src word_dst
                     text_src text_dst
                     btn_translate_word
                     vbox hbox_words vbox_dst hbox_dst_item

                     hbox_btn

                     item_id

                     hbox_add btn_additem btn_addexisting

                     btn_add_word btn_clear btn_tran
                     tran
                   | ];

sub new {
  my $class  = shift;
  my $self   = $class->SUPER::new( splice @_ => 1 );
  $self->tran( Dict::Learn::Translate->new() );
  $self->parent( shift );

  ### src
  $self->word_src( Wx::TextCtrl->new( $self, -1, '', [-1,-1], [-1,-1] ) );
  $self->btn_translate_word( Wx::Button->new( $self, -1, '<=>', [-1, -1] ));
  $self->word_note( Wx::TextCtrl->new( $self, -1, '', [-1,-1], [-1,-1] ) );

  ### dst
  $self->word_dst([]);
  $self->btn_additem( Wx::Button->new( $self, -1, '+', [-1, -1] ));
  $self->btn_addexisting( Wx::Button->new( $self, -1, '++', [-1, -1] ));
  # layout
  $self->hbox_dst_item([]);
  $self->vbox_dst( Wx::BoxSizer->new( wxVERTICAL ) );
  $self->hbox_add( Wx::BoxSizer->new( wxHORIZONTAL ) );
  $self->hbox_add->Add( $self->btn_additem, wxALIGN_LEFT|wxRIGHT, 5 );
  $self->hbox_add->Add( $self->btn_addexisting, wxALIGN_LEFT|wxRIGHT, 5 );
  $self->vbox_dst->Add($self->hbox_add, 0, wxALIGN_LEFT|wxRIGHT, 5);

  # $self->add_dst_item;

  ### hbox_words layout
  $self->hbox_words( Wx::BoxSizer->new( wxHORIZONTAL ) );
  $self->hbox_words->Add( $self->word_src, 2, wxALL|wxTOP, 5 );
  $self->hbox_words->Add( $self->btn_translate_word, 1, wxTOP, 5 );
  $self->hbox_words->Add( $self->vbox_dst, 4, wxALL|wxEXPAND, 5 );

  ### btn
  $self->btn_add_word( Wx::Button->new( $self, -1, 'Add/Save', [-1, -1] ));
  $self->btn_tran( Wx::Button->new( $self, -1, 'Translate', [-1, -1] ));
  $self->btn_clear( Wx::Button->new( $self, -1, 'Clear',    [-1, -1] ));
  # layout
  $self->hbox_btn( Wx::BoxSizer->new( wxHORIZONTAL ) );
  $self->hbox_btn->Add( $self->btn_add_word , 0, wxBOTTOM|wxALIGN_LEFT|wxLEFT, 5 );
  $self->hbox_btn->Add( $self->btn_tran , 0, wxBOTTOM|wxALIGN_LEFT|wxLEFT, 5 );
  $self->hbox_btn->Add( $self->btn_clear,  0, wxBOTTOM|wxALIGN_LEFT|wxLEFT, 5);

  ### main layout
  $self->vbox( Wx::BoxSizer->new( wxVERTICAL ) );
  $self->vbox->Add( $self->hbox_words ,  0, wxALL|wxGROW, 0 );
  $self->vbox->Add( $self->word_note, 0, wxALL|wxGROW, 5 );
  $self->vbox->Add( $self->hbox_btn,  0, wxALL|wxGROW,   5 );
  $self->SetSizer( $self->vbox );
  $self->Layout();
  $self->vbox->Fit( $self );

  # mode: undef - add, other - edit
  $self->item_id(undef);

  # events
  EVT_BUTTON( $self, $self->btn_add_word,        \&add                       );
  EVT_BUTTON( $self, $self->btn_additem,         sub { $self->add_dst_item } );
  EVT_BUTTON( $self, $self->btn_addexisting,     \&add_existing_item         );
  EVT_BUTTON( $self, $self->btn_clear,           \&clear_fields              );
  EVT_BUTTON( $self, $self->btn_translate_word,  \&translate_word            );
  $self
}

sub initialize_words {
  my $self = shift;
  my @words = $main::ioc->lookup('db')->get_all_words(
    $self->parent->dictionary->{language_tr_id}{language_id}
  );
  for (@words) {
    $self->popup_words->Append($_->{word}, $_->{word_id});
  }
  $self
}

sub select_word {
  my ($self, $event) = @_;
  my $el = $self->add_dst_item( $event->GetClientData(), 1 );
  $el->{word}->SetValue( $event->GetString );
  $self
}

sub make_dst_item {
  my ($self, $word_id, $ro) = @_;
  push @{ $self->hbox_dst_item } => Wx::BoxSizer->new( wxHORIZONTAL );
  my $id = $#{ $self->hbox_dst_item };
  $self->word_dst->[$id] = {
    word_id => $word_id,
    id      => $id,
    cbox    => Wx::ComboBox->new( $self, wxID_ANY, undef, wxDefaultPosition, wxDefaultSize, [ $self->import_wordclass ], wxCB_DROPDOWN|wxCB_READONLY, wxDefaultValidator  ),
    # word    => Wx::TextCtrl->new( $self, -1, '', [-1,-1], [-1,-1] ),
    word    => Wx::ComboBox->new( $self, wxID_ANY, undef, wxDefaultPosition, wxDefaultSize, [], wxCB_DROPDOWN, wxDefaultValidator  ),
    # btnp    => Wx::Button->new( $self, -1, '+', [-1, -1] ),
    btnm    => Wx::Button->new( $self, -1, '-', [-1, -1] ),
    parent_hbox => $self->hbox_dst_item->[$id]
  };
  # EVT_BUTTON( $self, $self->word_dst->[$id]{btnp}, sub { $self->add_dst_item(); } );
  EVT_BUTTON( $self, $self->word_dst->[$id]{btnm}, sub { $self->del_dst_item($id); } );
  EVT_TEXT(   $self, $self->word_dst->[$id]{word}, sub { $self->query_words($id); } );
  # p($self->word_dst->[$id]{word});
  $self->word_dst->[$id]{cbox}->SetSelection(0);
  $self->hbox_dst_item->[$id]->Add($self->word_dst->[$id]{cbox}, 2, wxALL, 0);
  $self->hbox_dst_item->[$id]->Add($self->word_dst->[$id]{word}, 4, wxALL|wxEXPAND, 0);
  # $self->hbox_dst_item->[$id]->Add($self->word_dst->[$id]{btnp}, 1, wxALL|wxTOP, 0);
  $self->hbox_dst_item->[$id]->Add($self->word_dst->[$id]{btnm}, 1, wxALL, 0);

  if ($ro) {
    $self->word_dst->[$id]{word}->SetEditable(0);
    $self->word_dst->[$id]{edit} = Wx::Button->new( $self, -1, 'e', [-1, -1] );
    EVT_BUTTON( $self, $self->word_dst->[$id]{edit}, sub { $self->edit_word_as_new($id) } );
    $self->hbox_dst_item->[$id]->Add($self->word_dst->[$id]{edit}, 1, wxALL, 0);
  }

  $self->word_dst->[$id]
}

sub query_words {
  my ($self, $id) = @_;
  my $cb = $self->word_dst->[$id]{word};
  # p($cb->GetValue());
  my @words = $main::ioc->lookup('db')->select_words(
    $self->parent->dictionary->{language_tr_id}{language_id},
    $cb->GetValue(),
  );
  # p(@words);
  $cb->Clear;
  for (@words) {
    $cb->Append($_->{word});
  }
}

sub add_dst_item {
  my ($self, $word_id, $ro) = @_;
  my $el = $self->make_dst_item( $word_id, $ro );
  # $self->vbox_dst->Add( $el->{parent_hbox}, 1, wxALL|wxGROW, 0 );
  my @children = $self->vbox_dst->GetChildren;
  $self->vbox_dst->Insert( $#children || 0, $el->{parent_hbox}, 1, wxALL|wxGROW, 0 );
  $self->Layout();
  $el
}

sub del_dst_item {
  my $self = shift;
  my $id = shift;
  for (qw[ cbox word btnm btnp ]) {
    next unless defined $self->word_dst->[$id]{$_};
    $self->word_dst->[$id]{$_}->Destroy();
    delete $self->word_dst->[$id]{$_};
  }
  $self->vbox_dst->Detach($self->hbox_dst_item->[$id])
    if defined $self->hbox_dst_item->[$id];
  $self->Layout();
  delete $self->hbox_dst_item->[$id];
  delete $self->word_dst->[$id]{parent_hbox};
  $self
}

sub edit_word_as_new {
  my ($self, $word_id) = @_;
  # set editable
  $self->word_dst->[$word_id]{word}->SetEditable(1);
  # remove example id
  $self->word_dst->[$word_id]{word_id} = undef;
  # remove edit button
  $self->word_dst->[$word_id]{edit}->Destroy();
  $self->word_dst->[$word_id]{parent_hbox}->Remove(
    $self->word_dst->[$word_id]{edit}
  );
  delete $self->word_dst->[$word_id]{edit};
  $self
}

sub add {
  my $self = shift;

  my %params = (
    word    => $self->word_src->GetValue(),
    note    => $self->word_note->GetValue(),
    lang_id => $self->parent->dictionary->{language_orig_id}{language_id},
  );
  for my $word_dst_item ( grep { defined } @{ $self->word_dst } ) {
    my $push_item = { word_id => $word_dst_item->{word_id} };
    if ($word_dst_item->{word}) {
      $push_item->{wordclass} = int($word_dst_item->{cbox}->GetSelection());
      if ($word_dst_item->{word}->GetSelection > 0) {
        $push_item->{word_id}  = $word_dst_item->{word}->GetClientData(
                                 $word_dst_item->{word}->GetValue() );
      } else {
        $push_item->{word}      = $word_dst_item->{word}->GetValue();
      }
      $push_item->{lang_id}   = $self->parent->dictionary->{language_tr_id}{language_id};
      # skip empty fields
      next unless $push_item->{word} =~ /^.+$/;
    }
    push @{$params{translate}} => $push_item;
  }
  if (defined $self->item_id and
              $self->item_id >= 0)
  {
    $params{word_id} = $self->item_id ;
    $main::ioc->lookup('db')->update_word(%params);
  } else {
    $main::ioc->lookup('db')->add_word(%params);
  }

  $self->clear_fields;
  $self->remove_all_dst;
  $self->add_dst_item;
  $self->parent->notebook->SetPageText(1 => "Word");

  # reload linked words
  $self->parent->p_addexample->load_words;

  $self
}

sub import_wordclass {
  my $self = shift;
  map { $_->{name_orig} } $main::ioc->lookup('db')->select_wordclass();
}

sub clear_fields {
  my $self = shift;
  $self->word_src->Clear;
  for my $word_dst_item ( grep { defined } @{ $self->word_dst } ) {
    next unless defined $word_dst_item->{word};
    $word_dst_item->{cbox}->SetSelection(0);
    $word_dst_item->{word}->Clear;
  }
  $self->word_note->Clear;
  $self->item_id(undef);
}

sub remove_all_dst {
  my $self = shift;
  for ( @{ $self->word_dst } ) {
    $self->del_dst_item($_->{id});
    delete $self->word_dst->[$_->{id}];
  }
}

sub load_word {
  my $self   = shift;
  my %params = @_;
  my $word   = $main::ioc->lookup('db')->select_word( $params{word_id} );
  my @translate;
  for my $rel_word (@{ $word->{rel_words} }) {
    push @translate => {
      word_id   => $rel_word->{word2_id}{word_id},
      word      => $rel_word->{word2_id}{word},
      wordclass => $rel_word->{wordclass_id},
      note      => $rel_word->{note},
    };
  }
  $self->fill_fields(
    word_id   => $word->{word_id},
    word      => $word->{word},
    wordclass => $word->{wordclass_id},
    note      => $word->{note},
    translate => \@translate,
  );
}

sub fill_fields {
  my $self   = shift;
  my %params = @_;
  $self->clear_fields;
  $self->remove_all_dst;
  $self->word_src->SetValue($params{word});
  $self->item_id( $params{word_id} );
  for my $word_tr ( @{ $params{translate} } ) {
    my $el = $self->add_dst_item($word_tr->{word_id});
    $el->{word}->SetValue($word_tr->{word});
    $el->{cbox}->SetSelection($word_tr->{wordclass});
  }
  $self->word_note->SetValue($params{note});

  $self->parent->notebook->SetPageText(
    1 => "Edit item id#".$self->item_id);
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
      $self->word_dst->[$i]{cbox}->SetSelection(
        $self->get_partofspeach_index($partofspeach)
      );
      $self->word_dst->[$i]{word}->SetValue( join ' | ' =>
        map { ref $_ eq 'ARRAY' ? $_->[0] : $_ } @{$res->{$partofspeach}}
      );
      $i++;
    }
  }
  else {
    $self->word_dst->[0]{word}->SetValue( $res->{_} );
  }
}

1;
