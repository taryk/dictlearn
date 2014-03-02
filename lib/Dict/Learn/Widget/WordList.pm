package Dict::Learn::Widget::WordList;

use Wx ':everything';
use Wx::Event ':everything';

use Moose;
extends 'Wx::PlComboPopup';

use common::sense;

use Database;

use Data::Printer;

=head1 NAME

Dict::Learn::Combo::WordList

=head1 DESCRIPTION

TODO add description

=head1 ATTRIBUTES

=head2 parent

TODO add description

=cut

has parent => (
    is  => 'rw',
    isa => 'Wx::PopupTransientWindow',
);

=head2 vbox

TODO add description

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

=head2 panel

TODO add description

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

=head2 lb_words

TODO add description

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

=head2 initialized

TODO add description

=cut

has initialized => (
    is  => 'rw',
    isa => 'Bool',
);

=head1 METHODS

=head2 Create

TODO add description

=cut

sub Create {
    my ($self, $parent) = @_;

    $self->parent($parent);
    $self->panel->SetSizer($self->vbox);
    $self->panel->Layout();
    $self->vbox->Fit($self->panel);

    return 1;
}

=head2 GetControl

TODO add description

=cut

sub GetControl {
    my $self = shift;

    $self->panel;
}

=head2 OnPopup

TODO add description

=cut

sub OnPopup {
    my $self = shift;

    $self->SUPER::OnPopup();

    unless ($self->initialized) {
        $self->initialize_words();
        $self->initialized(1);
    }
    # Wx::LogMessage( "Popping up" );
}

=head2 OnDismiss

TODO add description

=cut

sub OnDismiss {
    my $self = shift;

    $self->SUPER::OnDismiss();
    # Wx::LogMessage( "Being dismissed" );
}

=head2 GetStringValue

TODO add description

=cut

sub GetStringValue {
    my ($self) = @_;

    my $item_id = $self->lb_words->GetNextItem(-1, wxLIST_NEXT_ALL,
        wxLIST_STATE_SELECTED);
    $self->parent->GetParent()
        ->SetLabel($self->lb_words->GetItem($item_id, 0)->GetText());
    $self->lb_words->GetItem($item_id, 1)->GetText;
}

=head2 on_select

TODO add description

=cut

sub on_select {
    my ($self, $parent, $event) = @_;

    # $event->GetIndex
    my $text = $self->lb_words->GetItem($event->GetIndex, 1)->GetText;

    $self->Dismiss();
}

=head2 initialize_words

TODO add description

=cut

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
