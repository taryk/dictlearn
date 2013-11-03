package Dict::Learn::Combo::WordList 0.1;

use Wx qw[:everything];
use Wx::Event qw[:everything];

use Moose;
extends 'Wx::PlComboPopup';

use common::sense;

use Database;

use Data::Printer;

=item parent

=cut

has parent => (
    is  => 'rw',
    isa => 'Wx::PopupTransientWindow',
);

=item vbox

=cut

has vbox => (
    is         => 'ro',
    isa        => 'Wx::BoxSizer',
    lazy_build => 1,
);

sub _build_vbox {
    my $self = shift;

    my $vbox = Wx::BoxSizer->new(wxVERTICAL);
    $vbox->Add($self->lb_words, 1, wxEXPAND | wxTOP | wxLEFT | wxRIGHT, 2);

    return $vbox;
}

=item panel

=cut

has panel => (
    is         => 'ro',
    isa        => 'Wx::Panel',
    lazy_build => 1,
);

sub _build_panel {
    my $self = shift;

    my $panel = Wx::Panel->new($self->parent, wxID_ANY,
        wxDefaultPosition, wxDefaultSize, wxCAPTION, 'words');

    return $panel;
}

=item lb_words

=cut

has lb_words => (
    is         => 'ro',
    isa        => 'Wx::ListCtrl',
    lazy_build => 1,
);

sub _build_lb_words {
    my $self = shift;

    my $lb_words
        = Wx::ListCtrl->new($self->panel, wxID_ANY,
        wxDefaultPosition, wxDefaultSize,
        wxLC_REPORT | wxLC_HRULES | wxLC_VRULES);

    $lb_words->InsertColumn(0, 'id',   wxLIST_FORMAT_LEFT, 35);
    $lb_words->InsertColumn(1, 'word', wxLIST_FORMAT_LEFT, 200);

    EVT_LIST_ITEM_ACTIVATED($self->parent, $lb_words,
        sub { $self->on_select(@_) });

    return $lb_words;
}

=item initialized

=cut

has initialized => (
    is  => 'rw',
    isa => 'Bool',
);

sub Create {
    my ($self, $parent) = @_;

    $self->parent($parent);
    $self->panel->SetSizer($self->vbox);
    $self->panel->Layout();
    $self->vbox->Fit($self->panel);

    return 1;
}

sub GetControl {
    my $self = shift;

    $self->panel;
}

sub OnPopup {
    my $self = shift;

    $self->SUPER::OnPopup();

    unless ($self->initialized) {
        $self->initialize_words();
        $self->initialized(1);
    }
    # Wx::LogMessage( "Popping up" );
}

sub OnDismiss {
    my $self = shift;

    $self->SUPER::OnDismiss();
    # Wx::LogMessage( "Being dismissed" );
}

sub GetStringValue {
    my ($self) = @_;

    my $item_id = $self->lb_words->GetNextItem(-1, wxLIST_NEXT_ALL,
        wxLIST_STATE_SELECTED);
    $self->parent->GetParent()
        ->SetLabel($self->lb_words->GetItem($item_id, 0)->GetText());
    $self->lb_words->GetItem($item_id, 1)->GetText;
}

sub on_select {
    my ($self, $parent, $event) = @_;

    # $event->GetIndex
    my $text = $self->lb_words->GetItem($event->GetIndex, 1)->GetText;

    $self->Dismiss();
}

sub initialize_words {
    my $self = shift;

    $self->lb_words->DeleteAllItems();
    my @words
        = Database->schema->resultset('Word')
        ->get_all_cached(
        Dict::Learn::Dictionary->curr->{language_tr_id}{language_id});
    for (@words) {
        my $id = $self->lb_words->InsertItem(Wx::ListItem->new);
        $self->lb_words->SetItem($id, 0, $_->{word_id});
        $self->lb_words->SetItem($id, 1, $_->{word});
    }
}

no Moose;
__PACKAGE__->meta->make_immutable( inline_constructor => 0 );
1;
