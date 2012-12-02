package Dict::Learn::Frame::AddExample 0.1;

use Wx qw[:everything];
use Wx::Grid;
use Wx::Event qw[:everything];

use base 'Wx::Panel';

use LWP::UserAgent;

# use lib qw[ ];

use Dict::Learn::Translate;
use Dict::Learn::Dictionary;
use Dict::Learn::Combo::Button;

use common::sense;

use Data::Printer;

use Scalar::Util qw[ weaken ];

use Class::XSAccessor
  accessors => [ qw| parent
                     text_src text_dst example_note
                     vbox vbox_src vbox_dst hbox_dst_item

                     hbox_examples hbox_btn

                     search_words linked_words
                     item_id
                     hbox_add btn_additem btn_addexisting
                     btn_add btn_clear btn_tran btn_cancel
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
  $self->vbox_src->Add( $self->text_src,     3, wxALL|wxEXPAND, 5 );
  $self->vbox_src->Add( $self->example_note, 0, wxALL|wxGROW,   5 );
  $self->vbox_src->Add( $self->search_words, 0, wxALL|wxGROW,   5 );
  $self->vbox_src->Add( $self->linked_words, 3, wxALL|wxEXPAND, 5 );

  ### dst
  $self->text_dst([]);
  $self->btn_additem( Wx::Button->new( $self, -1, '+', [-1, -1] ));
  $self->btn_addexisting( Dict::Learn::Combo::Button->new( $self, -1, "++", [-1,-1] ));
  # layout
  $self->hbox_add( Wx::BoxSizer->new( wxHORIZONTAL ) );
  $self->hbox_add->Add( $self->btn_additem,     wxALIGN_LEFT|wxRIGHT, 5 );
  $self->hbox_add->Add( $self->btn_addexisting, wxALIGN_LEFT|wxRIGHT, 5 );

  # layout
  $self->vbox_dst( Wx::BoxSizer->new( wxVERTICAL ) );
  $self->hbox_dst_item([]);
  $self->vbox_dst->Add($self->hbox_add, 0, wxALIGN_LEFT|wxLEFT|wxTOP, 5);

  ### hbox_examples layout
  $self->hbox_examples( Wx::BoxSizer->new( wxHORIZONTAL ) );
  $self->hbox_examples->Add( $self->vbox_src, 2, wxALL|wxEXPAND, 0 );
  $self->hbox_examples->Add( $self->vbox_dst, 3, wxALL|wxEXPAND, 0 );

  ### btn
  $self->btn_add(    Wx::Button->new( $self, -1, 'Add Example', [-1, -1] ));
  $self->btn_tran(   Wx::Button->new( $self, -1, 'Translate',   [-1, -1] ));
  $self->btn_clear(  Wx::Button->new( $self, -1, 'Clear',       [-1, -1] ));
  $self->btn_cancel( Wx::Button->new( $self, -1, 'Cancel',      [-1, -1] ));
  # layout
  $self->hbox_btn( Wx::BoxSizer->new( wxHORIZONTAL ) );
  $self->hbox_btn->Add( $self->btn_add,    0, wxBOTTOM|wxALIGN_LEFT|wxLEFT, 5 );
  $self->hbox_btn->Add( $self->btn_tran,   0, wxBOTTOM|wxALIGN_LEFT|wxLEFT, 5 );
  $self->hbox_btn->Add( $self->btn_clear,  0, wxBOTTOM|wxALIGN_LEFT|wxLEFT, 5 );
  $self->hbox_btn->Add( $self->btn_cancel, 0, wxBOTTOM|wxALIGN_LEFT|wxLEFT, 5 );


  ### main layout
  $self->vbox( Wx::BoxSizer->new( wxVERTICAL ) );
  $self->vbox->Add( $self->hbox_examples, 1, wxALL|wxGROW, 0 );
  $self->vbox->Add( $self->hbox_btn,      0, wxALL|wxGROW, 0 );
  $self->SetSizer( $self->vbox );
  $self->Layout();
  $self->vbox->Fit( $self );

  # mode: undef - add, other - edit
  $self->item_id(undef);

  # events
  EVT_BUTTON( $self, $self->btn_add,     \&add                       );
  EVT_BUTTON( $self, $self->btn_additem, sub { $self->add_dst_item } );
  EVT_BUTTON( $self, $self->btn_clear,   \&clear_fields              );
  EVT_BUTTON( $self, $self->btn_tran,    \&translate                 );
  EVT_BUTTON( $self, $self->btn_cancel,  \&cancel                    );

  EVT_SELECTED( $self, $self->btn_addexisting, sub { $self->add_existing_item(@_) } );

  Dict::Learn::Dictionary->cb(sub {
    my $dict = shift;
    $self->load_words;
    $self->btn_addexisting->init;
  });

  $self
}

sub add_existing_item {
  my ($self, $example_id, $example) = @_;
  my $el = $self->add_dst_item( $example_id, 1 );
  $el->{text}->SetValue( $example );
}

sub make_dst_item {
  my ($self, $example_id, $ro) = @_;
  push @{ $self->hbox_dst_item } => Wx::BoxSizer->new( wxHORIZONTAL );
  my $id = $#{ $self->hbox_dst_item };
  my $text;
  $self->text_dst->[$id] = {
    example_id  => $example_id,
    id          => $id,
    text        => Wx::TextCtrl->new( $self, -1, '', [-1,-1], [-1,-1], wxTE_MULTILINE ),
    vbox        => Wx::BoxSizer->new( wxVERTICAL ),
    btnm        => Wx::Button->new( $self, -1, '-', [-1, -1] ),
    parent_hbox => $self->hbox_dst_item->[$id],
  };
  EVT_BUTTON( $self, $self->text_dst->[$id]{btnm}, sub { $self->del_dst_item($id); } );
  $self->hbox_dst_item->[$id]->Add($self->text_dst->[$id]{text}, 4, wxALL|wxEXPAND, 0);
  $self->hbox_dst_item->[$id]->Add($self->text_dst->[$id]{vbox}, 1, wxALL, 0);
  $self->text_dst->[$id]{vbox}->Add($self->text_dst->[$id]{btnm}, 1, wxALL, 0);

  if ($ro) {
    # set readonly
    $self->text_dst->[$id]{text}->SetEditable(0);
    # add 'edit as new' button
    $self->text_dst->[$id]{edit} = Wx::Button->new( $self, -1, 'e', [-1, -1] );
    EVT_BUTTON( $self, $self->text_dst->[$id]{edit}, sub { $self->edit_example_as_new($id) } );
    $self->text_dst->[$id]{vbox}->Add($self->text_dst->[$id]{edit}, 1, wxALL, 0);
  }

  $self->text_dst->[$id]
}

sub add_dst_item {
  my ($self, $example_id, $ro) = @_;
  my $el = $self->make_dst_item( $example_id, $ro );
  # $self->vbox_dst->Add( $el->{parent_hbox}, 1, wxALL|wxGROW, 5 );
  my @children = $self->vbox_dst->GetChildren;
  $self->vbox_dst->Insert( $#children || 0, $el->{parent_hbox}, 1, wxALL|wxGROW, 5 );
  $self->Layout();
  $el
}

sub del_dst_item {
  my $self = shift;
  my $id = shift;
  for (qw[ btnm edit ]) {
    next unless defined $self->text_dst->[$id]{$_};
    $self->text_dst->[$id]{vbox}->Remove($self->text_dst->[$id]{$_});
    $self->text_dst->[$id]{$_}->Destroy();
    delete $self->text_dst->[$id]{$_};
  }
  for (qw[ text vbox ]) {
    next unless defined $self->text_dst->[$id]{$_};
    $self->text_dst->[$id]{$_}->Destroy();
    delete $self->text_dst->[$id]{$_};
  }
  $self->vbox_dst->Detach($self->hbox_dst_item->[$id])
    if defined $self->hbox_dst_item->[$id];
  $self->Layout();
  delete $self->hbox_dst_item->[$id];
  delete $self->text_dst->[$id]{parent_hbox};
  $self
}

sub edit_example_as_new {
  my ($self, $example_id) = @_;
  # set editable
  $self->text_dst->[$example_id]{text}->SetEditable(1);
  # remove example id
  $self->text_dst->[$example_id]{example_id} = undef;
  # remove edit button
  $self->text_dst->[$example_id]{edit}->Destroy();
  $self->text_dst->[$example_id]{vbox}->Remove(
    $self->text_dst->[$example_id]{edit}
  );
  delete $self->text_dst->[$example_id]{edit};
  $self
}

sub add {
  my $self = shift;
  return unless $self->text_src->GetValue or
                $self->text_src->GetValue !~ /^\s+$/;
  my %params = (
    text    => $self->text_src->GetValue(),
    note    => $self->example_note->GetValue(),
    lang_id => Dict::Learn::Dictionary->curr->{language_orig_id}{language_id},
    dictionary_id => Dict::Learn::Dictionary->curr_id,
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
    my $push_item = { example_id  => $text_dst_item->{example_id} };
    if ($text_dst_item->{text}) {
      if (defined $text_dst_item->{example_id} and
                  $text_dst_item->{example_id} >= 0)
      {
        $push_item->{example_id} = $text_dst_item->{example_id};
        $push_item->{text} = 0;
      }
      else {
        $push_item->{text}    = $text_dst_item->{text}->GetValue;
        $push_item->{lang_id} = Dict::Learn::Dictionary->curr->{language_tr_id}{language_id};
      }
    }
    push @{ $params{translate} } => $push_item;
  }


  if (defined $self->item_id and
              $self->item_id >= 0)
  {
    $params{example_id} = $self->item_id;
    $main::ioc->lookup('db')->update_example(%params);
    $self->parent->notebook->SetPageText(2 => "Example");
  } else {
    $main::ioc->lookup('db')->add_example(%params);
  }

  $self->clear_fields;
  $self->remove_all_dst;

  $self
}

sub clear_fields {
  my $self = shift;
  $self->text_src->Clear;
  for my $text_dst_item ( @{ $self->text_dst } ) {
    next unless defined $text_dst_item->{text};
    $text_dst_item->{text}->Clear;
  }
  $self->text_src->Clear;
  $self->example_note->Clear;
  $self->item_id(undef);
}

sub remove_all_dst {
  my $self = shift;
  for ( @{ $self->text_dst } ) {
    $self->del_dst_item($_->{id});
    delete $self->text_dst->[$_->{id}];
  }
}

# @TODO get related words
sub load_example {
  my $self    = shift;
  my %params  = @_;
  my $example = $main::ioc->lookup('db')->select_example( $params{example_id} );
  my @translate;
  for my $rel_example ( @{ $example->{rel_examples} } ) {
    push @translate => {
      example_id => $rel_example->{example2_id}{example_id},
      text       => $rel_example->{example2_id}{example},
      note       => $rel_example->{note},
      wordclass  => $rel_example->{wordclass_id},
    };
  }
  $self->fill_fields(
    example_id => $example->{example_id},
    text       => $example->{example},
    note       => $example->{note},
    translate  => \@translate,
  );
}

sub fill_fields {
  my $self   = shift;
  my %params = @_;
  $self->clear_fields;
  $self->remove_all_dst;
  $self->item_id( $params{example_id} );
  $self->text_src->SetValue( $params{text} );
  $self->example_note->SetValue( $params{note} );
  for my $text_tr ( @{ $params{translate} } ) {
    my $el = $self->add_dst_item($text_tr->{example_id} => 1);
    $el->{text}->SetValue($text_tr->{text});
  }
  $self->parent->notebook->SetPageText(
    2 => "Edit example id#".$self->item_id);
}

sub load_words {
  my $self = shift;
  $self->linked_words->Clear;
  for my $item ( $main::ioc->lookup('db')->select_words(
    Dict::Learn::Dictionary->curr->{language_orig_id}{language_id} ))
  {
    $self->search_words->Append($item->{word}." (".$item->{wordclass}.")", $item->{id});
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

sub cancel {
  my $self = shift;
  $self->clear_fields();
  $self->remove_all_dst();
  $self->parent->notebook->SetPageText(2 => "Example");
}

1;
