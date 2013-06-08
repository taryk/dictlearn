package Dict::Learn::Combo::Button 0.1;

use Wx qw[:everything];
use Wx::Event qw[:everything];

use Exporter qw[import];
use base qw[Wx::Button];

use Dict::Learn::Combo::ExamplesList;

use Data::Printer;

our @EXPORT = qw[ EVT_SELECTED ];

use Class::XSAccessor accessors => [qw| parent popup_window button vbox |];

use common::sense;

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);
    $self->parent($_[0]);
    $self->popup_window(
        Dict::Learn::Combo::ExamplesList->new($self, wxBORDER_DEFAULT));
    EVT_BUTTON($self, $self, \&OnClick);
    $self;
}

sub OnClick {
    my ($self, $event) = @_;
    $self->popup_window->Popup();
    $self->popup_window->SetSize(
        $self->GetScreenPosition->x,
        $self->GetScreenPosition->y + $self->GetRect->height,
        250, 150
    );
    $self->popup_window->Layout();
}

sub init {
    my $self = shift;
    $self->popup_window->initialize_examples;
    $self;
}

sub EVT_SELECTED {
    my ($parent, $obj, $sub) = @_;
    $obj->popup_window->cb($sub);
}

1;
