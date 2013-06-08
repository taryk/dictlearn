package Dict::Learn::Combo::WordList 0.1;
use base qw[ Wx::PlComboPopup ];

use Wx qw[:everything];
use Wx::Event qw[:everything];

use Data::Printer;

use common::sense;

use Class::XSAccessor accessors => [qw| parent vbox panel search lb_words |];

sub Init {
    my $self = shift;
    $self->{item_index} = undef;
    $self->{cb}         = undef;
    $self;
}

sub Create {
    my ($self, $parent) = @_;
    $self->parent($parent);

    # widgets
    $self->panel(
        Wx::Panel->new(
            $parent,           wxID_ANY,
            wxDefaultPosition, wxDefaultSize,
            wxCAPTION,         'words'
        )
    );

    # $self->search( Wx::TextCtrl->new( $self->panel, wxID_ANY, 'test', wxDefaultPosition, wxDefaultSize ) );
    # $self->search->SetEditable(1);
    $self->lb_words(
        Wx::ListCtrl->new(
            $self->panel,      wxID_ANY,
            wxDefaultPosition, wxDefaultSize,
            wxLC_REPORT | wxLC_HRULES | wxLC_VRULES
        )
    );
    $self->lb_words->InsertColumn(0, 'id',   wxLIST_FORMAT_LEFT, 35);
    $self->lb_words->InsertColumn(1, 'word', wxLIST_FORMAT_LEFT, 200);
    $self->initialize_words();

    # layout
    $self->vbox(Wx::BoxSizer->new(wxVERTICAL));

    # $self->vbox->Add( $self->search, 0, wxEXPAND|wxTOP|wxLEFT|wxRIGHT, 2 );
    $self->vbox->Add($self->lb_words, 1, wxEXPAND | wxTOP | wxLEFT | wxRIGHT,
        2);

    # main
    $self->panel->SetSizer($self->vbox);
    $self->panel->Layout();
    $self->vbox->Fit($self->panel);
    EVT_LIST_ITEM_ACTIVATED($parent, $self->lb_words,
        sub { $self->on_select(@_) });

    $self->panel;
}

sub GetControl {
    my $self = shift;

    # p($self);
    # say "GetControl";
    $self->panel;
}

sub OnPopup {
    my $self = shift;
    $self->SUPER::OnPopup();

    # Wx::LogMessage( "Popping up" );
}

sub OnDismiss {
    my $self = shift;
    $self->SUPER::OnDismiss();

    # Wx::LogMessage( "Being dismissed" );
}

sub SetStringValue {
    my ($self, $string) = @_;

    # p($string);
}

sub GetStringValue {
    my ($self) = @_;
    my $item_id = $self->lb_words->GetNextItem(-1, wxLIST_NEXT_ALL,
        wxLIST_STATE_SELECTED);
    $self->parent->GetParent()
        ->SetLabel($self->lb_words->GetItem($item_id, 0)->GetText());
    $self->lb_words->GetItem($item_id, 1)->GetText;
}

sub cb {
    my ($self, $cb) = @_;
    return unless ref $cb eq 'CODE';
    $self->{cb} = $cb;
}

sub on_select {
    my ($self, $parent, $event) = @_;

    # p($event->GetIndex);
    my $text = $self->lb_words->GetItem($event->GetIndex, 1)->GetText;

    # p($text);
    $self->Dismiss();
}

sub initialize_words {
    my $self = shift;
    my @words
        = $main::ioc->lookup('db')->schema->resultset('Word')
        ->get_all_cached(
        Dict::Learn::Dictionary->curr->{language_tr_id}{language_id});
    $self->lb_words->DeleteAllItems();
    for (@words) {
        my $id = $self->lb_words->InsertItem(Wx::ListItem->new);
        $self->lb_words->SetItem($id, 0, $_->{word_id});
        $self->lb_words->SetItem($id, 1, $_->{word});
    }
}

1;
