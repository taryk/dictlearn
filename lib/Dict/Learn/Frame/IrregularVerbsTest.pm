package Dict::Learn::Frame::IrregularVerbsTest 0.1;

use Wx qw[:everything];
use Wx::Grid;
use Wx::Event qw[:everything];

use base 'Wx::Panel';

use Data::Printer;

use common::sense;

use Class::XSAccessor
  accessors => [ qw| parent
                     l_position
                     l_word e_word2 e_word3
                     btn_next btn_prev btn_reset
                     vbox hbox_words hbox_buttons

                     p_current p_min p_max
                   | ];

use constant {
  STEPS => 10
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
  $self->vbox->Add( $self->hbox_buttons, 0, wxTOP|wxGROW, 20 );
  $self->SetSizer( $self->vbox );
  $self->Layout();
  $self->vbox->Fit( $self );

  $self->p_min(1);
  $self->p_max(STEPS);
  $self->init_test();

  # events
  EVT_BUTTON( $self, $self->btn_prev,  \&prev_word );
  EVT_BUTTON( $self, $self->btn_next,  \&next_word );
  EVT_BUTTON( $self, $self->btn_reset, \&reset_test );
  $self
}

sub init_test {
  my ($self) = @_;
  $self->clear_fields();
  $self->set_position($self->p_min);
}

sub next_word {
  my ($self) = @_;
  return unless $self->p_current < $self->p_max;
  $self->clear_fields();
  $self->set_position($self->p_current+1);
}

sub prev_word {
  my ($self) = @_;
  return unless $self->p_current > $self->p_min;
  $self->clear_fields();
  $self->set_position($self->p_current-1);
}

sub set_position {
  my ($self, $position) = @_;
  $self->p_current($position);
  $self->l_position->SetLabel($self->p_current.'/'.STEPS);
}

sub load_fields {
  my ($self, @words) = @_;
  $self->l_word->SetLabel($words[0])  if $words[0];
  $self->e_word2->SetValue($words[1]) if $words[1];
  $self->e_word3->SetValue($words[2]) if $words[2];
  $self->Layout();
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

1;
