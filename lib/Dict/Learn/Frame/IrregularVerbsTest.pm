package Dict::Learn::Frame::IrregularVerbsTest 0.1;

use Wx qw[:everything];
use Wx::Grid;
use Wx::Event qw[:everything];

use base 'Wx::Panel';

use List::Util qw[shuffle];
use Dict::Learn::Frame::IrregularVerbsTest::Result;

use Data::Printer;

use common::sense;

use Class::XSAccessor
  accessors => [ qw| parent
                     l_position
                     l_word e_word2 e_word3
                     res res_word2 res_word3
                     btn_next btn_prev btn_reset
                     vbox hbox_words hbox_res hbox_buttons

                     p_current p_min p_max

                     words exercise total_score
                   | ];

use constant {
  TEST_ID => 0,
  STEPS   => 10
};

sub new {
  my $class = shift;
  my $self  = $class->SUPER::new( splice @_ => 1 );
  $self->parent( shift );

  ### position
  $self->l_position( Wx::StaticText->new($self, wxID_ANY, '1/10', wxDefaultPosition, wxDefaultSize, wxALIGN_CENTRE) );

  ### words
  $self->l_word(  Wx::StaticText->new($self, wxID_ANY, 'Word', wxDefaultPosition, wxDefaultSize, wxALIGN_CENTRE) );
  $self->e_word2( Wx::TextCtrl->new($self, wxID_ANY, '', wxDefaultPosition, wxDefaultSize, wxTE_LEFT) );
  $self->e_word3( Wx::TextCtrl->new($self, wxID_ANY, '', wxDefaultPosition, wxDefaultSize, wxTE_LEFT) );
  # layout
  $self->hbox_words( Wx::BoxSizer->new( wxHORIZONTAL ) );
  $self->hbox_words->Add($self->l_word,  0, wxRIGHT|wxTOP|wxLEFT|wxEXPAND, 5);
  $self->hbox_words->Add($self->e_word2, 1, wxRIGHT|wxEXPAND, 5);
  $self->hbox_words->Add($self->e_word3, 1, wxEXPAND, 0);

  ### res
  $self->res(  Wx::StaticText->new($self, wxID_ANY, '', wxDefaultPosition, wxDefaultSize, wxALIGN_CENTRE) );
  $self->res_word2(  Wx::StaticText->new($self, wxID_ANY, '', wxDefaultPosition, wxDefaultSize, wxALIGN_CENTRE) );
  $self->res_word3(  Wx::StaticText->new($self, wxID_ANY, '', wxDefaultPosition, wxDefaultSize, wxALIGN_CENTRE) );
  # layout
  $self->hbox_res( Wx::BoxSizer->new( wxHORIZONTAL ) );
  $self->hbox_res->Add($self->res,    0, wxRIGHT|wxTOP|wxLEFT|wxEXPAND, 5);
  $self->hbox_res->Add($self->res_word2, 1, wxRIGHT|wxEXPAND, 5);
  $self->hbox_res->Add($self->res_word3, 1, wxEXPAND, 0);

  ### buttons
  $self->btn_prev(  Wx::Button->new($self, wxID_ANY, 'Prev',  wxDefaultPosition, wxDefaultSize) );
  $self->btn_next(  Wx::Button->new($self, wxID_ANY, 'Next',  wxDefaultPosition, wxDefaultSize) );
  $self->btn_reset( Wx::Button->new($self, wxID_ANY, 'Reset', wxDefaultPosition, wxDefaultSize) );
  # layout
  $self->hbox_buttons( Wx::BoxSizer->new( wxHORIZONTAL ) );
  $self->hbox_buttons->Add($self->btn_prev,  0, wxALL|wxGROW,  0);
  $self->hbox_buttons->Add($self->btn_next,  0, wxALL|wxGROW,  0);
  $self->hbox_buttons->Add($self->btn_reset, 0, wxLEFT|wxGROW, 40);

  ### main layout
  $self->vbox( Wx::BoxSizer->new( wxVERTICAL ) );
  $self->vbox->Add( $self->l_position,   0, wxTOP|wxGROW, 5  );
  $self->vbox->Add( $self->hbox_words,   0, wxTOP|wxGROW, 20 );
  $self->vbox->Add( $self->hbox_res,     0, wxTOP|wxGROW, 5  );
  $self->vbox->Add( $self->hbox_buttons, 0, wxTOP|wxGROW, 20 );
  $self->SetSizer( $self->vbox );
  $self->Layout();
  $self->vbox->Fit( $self );

  $self->p_min(1);
  $self->p_max(STEPS);
  $self->total_score(0);
  $self->init_test();

  # events
  EVT_BUTTON( $self, $self->btn_prev,  \&prev_word  );
  EVT_BUTTON( $self, $self->btn_next,  \&next_word  );
  EVT_BUTTON( $self, $self->btn_reset, \&reset_test );
  EVT_KEY_UP( $self, sub { $self->keybind($_[1]) } );
  EVT_KEY_UP( $self->e_word2, sub { $self->keybind2($_[1]) } );
  EVT_KEY_UP( $self->e_word3, sub { $self->keybind3($_[1]) } );
  $self
}

sub keybind {
  my ($self, $event) = @_;
  # p($event);
  my $key = $event->GetKeyCode();
  if ($key == WXK_RETURN) {
    $self->next_word();
  }
}

sub keybind2 {
  my ($self, $event) = @_;
  my $key = $event->GetKeyCode();
  if ($key == WXK_RETURN) {
    $self->e_word3->SetFocus();
  }
  elsif ($event->AltDown() and $key == WXK_BACK)
  {
    $self->prev_word();
  }
}

sub keybind3 {
  my ($self, $event) = @_;
  my $key = $event->GetKeyCode();
  if ($event->GetKeyCode() == WXK_RETURN) {
    $self->next_word();
  }
  elsif ($event->AltDown() and $key == WXK_BACK)
  {
    $self->e_word2->SetFocus();
  }
}

sub get_word {
  my ($self, $id, $n) = @_;
  $n //= 1;
  my $words_c = scalar @{ $self->words };
  return unless $words_c > 0;
  $id %= $words_c if $id >= $words_c;
  return unless defined $self->words->[$id];
  return $self->words->[$id]
}

sub get_step {
  my ($self, $id) = @_;
  return $self->exercise->[$id]
    if defined $self->exercise->[$id];
}

sub init_test {
  my ($self) = @_;
  $self->exercise([]);
  $self->clear_fields();
  $self->set_position($self->p_min);
  $self->words(
    [ shuffle $main::ioc->lookup('db')->schema->resultset('Word')->get_irregular_verbs( STEPS ) ]
  );
  printf "Received %d verbs for test\n" => scalar @{ $self->words };
  for (my $id = $self->p_min-1; $id < $self->p_max; $id++)
  {
    my $word = $self->get_word($id);
    push @{$self->exercise} => {
      word_id => $word->{word_id},
      word    => [ $word->{word}, $word->{word2}, $word->{word3} ],
      user    => [ undef, [ undef, 0 ], [ undef, 0 ] ],
      score   => undef,
      end     => 0,
    };
  }
  $self->load_step($self->p_current);
}

sub write_step_res {
  my ($self, $id, $end) = @_;
  $end //= 1;
  my $ex = $self->exercise->[$id-1];
  $ex->{end}  = $end;
  return if $ex->{score} and $ex->{score} >= 0;
  $ex->{user} = [
    undef,
    [ $self->e_word2->GetValue => $self->e_word2->GetValue eq $ex->{word}[1] ? 0.5 : 0 ],
    [ $self->e_word3->GetValue => $self->e_word3->GetValue eq $ex->{word}[2] ? 0.5 : 0 ]
  ],
  $ex->{score} = $ex->{user}[1][1] + $ex->{user}[2][1];
  $self->total_score($self->total_score + $ex->{score});
}

sub next_word {
  my ($self) = @_;
  $self->write_step_res($self->p_current);
  if ($self->p_current >= $self->p_max) {
    $self->result();
    return;
  }
  $self->clear_fields();
  $self->set_position($self->p_current+1);
  $self->load_step($self->p_current);
}

sub prev_word {
  my ($self) = @_;
  return unless $self->p_current > $self->p_min;
  $self->write_step_res($self->p_current, 0);
  $self->clear_fields();
  $self->set_position($self->p_current-1);
  $self->load_step($self->p_current);
  $self->SetFocus();
}

sub set_position {
  my ($self, $position) = @_;
  $self->p_current($position);
  $self->l_position->SetLabel($self->p_current.'/'.STEPS);
}

sub load_fields {
  my ($self, $en, @words) = @_;
  $self->l_word->SetLabel($words[0])  if $words[0];
  $self->e_word2->SetValue($words[1]) if $words[1];
  $self->e_word3->SetValue($words[2]) if $words[2];
  $self->e_word2->Enable($en);
  $self->e_word3->Enable($en);
  $self->e_word2->SetFocus();
  $self->Layout();
}

sub load_step {
  my ($self, $id) = @_;
  my $step = $self->get_step($id-1);
  $self->load_fields(
    !$step->{end}    ,
    $step->{word}[0] ,
    $step->{user}[1][0] ,
    $step->{user}[2][0]
  );
}

sub clear_fields {
  my ($self) = @_;
  $self->l_word->SetLabel('');
  $self->e_word2->Clear;
  $self->e_word3->Clear;
  $self->Layout();
}

sub reset_test {
  my ($self) = @_;
  $self->init_test();
}

sub result {
  my ($self) = @_;
  my $result_dialog = Dict::Learn::Frame::IrregularVerbsTest::Result->new(
    $self, wxID_ANY, 'Result', wxDefaultPosition, wxDefaultSize,
    wxDEFAULT_DIALOG_STYLE|wxRESIZE_BORDER|wxSTAY_ON_TOP
  );
  if ($result_dialog->fill_result($self->exercise)->ShowModal() == wxID_OK)
  {
    $main::ioc->lookup('db')->schema->resultset('TestSession')->add( TEST_ID,
      $self->total_score,
      $self->exercise
    );
  }
  $result_dialog->Destroy();
  $self->reset_test();
}

1;
