package Dict::Learn::Frame::Sidebar 0.1;

use Wx qw[:everything];
use Wx::Event qw[:everything];
use Wx::Html;

use base 'Wx::Panel';

use common::sense;
use Carp qw[croak confess];
use Data::Printer;

use Class::XSAccessor
  accessors => [ qw| parent vbox html btn_refresh
                   | ];

sub new {
  my $class = shift;
  my $self  = $class->SUPER::new( @_ );
  $self->parent(shift);

  $self->html(Wx::HtmlWindow->new($self, wxID_ANY, wxDefaultPosition, wxDefaultSize));
  $self->html->SetPage("Dict::Learn");

  $self->btn_refresh( Wx::Button->new( $self, wxID_ANY, 'Refresh', wxDefaultPosition, wxDefaultSize ) );

  ### main layout
  $self->vbox( Wx::BoxSizer->new( wxVERTICAL ) );
  $self->vbox->Add( $self->html, 1, wxEXPAND|wxALL, 0 );
  $self->vbox->Add($self->btn_refresh, 0, wxTOP, 5 );
  $self->SetSizer( $self->vbox );
  $self->Layout();
  $self->vbox->Fit( $self );

  $self
}

sub load_word {
  my ($self, %params) = @_;
  my $word = $main::ioc->lookup('db')->schema->resultset('Word')->select_one( $params{word_id} );
  my @translate;
  for my $rel_word (@{ $word->{rel_words} }) {
    next unless $rel_word->{word2_id} or $rel_word->{word2_id}{word_id};
    push @translate => {
      word_id   => $rel_word->{word2_id}{word_id},
      word      => $rel_word->{word2_id}{word},
      wordclass => $rel_word->{wordclass_id},
      note      => $rel_word->{note},
    };
  }
  $self->html->SetPage(
    $self->gen_html(
      word_id   => $word->{word_id},
      word      => $word->{word},
      word2     => $word->{word2},
      word3     => $word->{word3},
      irregular => $word->{irregular},
      wordclass => $word->{wordclass_id},
      note      => $word->{note},
      translate => \@translate,
    )
  );
}

sub gen_html {
  my ($self, %params) = @_;
  my ($word_line,$translate,$note);

  # word line
  $word_line  = '<h3>'.$params{word}.'</h3>';
  $word_line .= '<i>past simple:</i> <b> '.$params{word2}.'</b><br> ' if $params{word2};
  $word_line .= '<i>past participle:</i> <b> '.$params{word3}.'</b><br> ' if $params{word3};

  # translation
  $translate = "<ol>";
  for (@{ $params{translate} }) {
    $translate .= '<li>' . $_->{word}
      . ( $_->{note} ? '<i>('.$_->{note}.')</i>' : '' )
      . '</li>';
  }
  $translate.='</ol>';

  # note
  $note = sprintf('note: <i>%s</i>', $params{note}) if $params{note};

  # result
  $word_line . '<br><br>' . $translate . '<br><br>' . $note // ''
}

1;
