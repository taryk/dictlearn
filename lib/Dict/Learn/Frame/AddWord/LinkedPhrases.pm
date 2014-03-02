package Dict::Learn::Frame::AddWord::LinkedPhrases;

use Wx ':everything';
use Wx::Event ':everything';

use Moose;
use MooseX::NonMoose;
extends 'Wx::ScrolledWindow';

use Carp qw(croak confess);
use Data::Printer;
use List::Util 'first';

use Database;
use Dict::Learn::Widget::WordList;

use common::sense;

=head1 NAME

Dict::Learn::Frame::AddWord::LinkedPhrases

=head1 DESCRIPTION

TODO add description

=head1 ATTRIBUTES

=head2 parent

TODO add description

=cut

has parent => (
    is  => 'ro',
    isa => 'Dict::Learn::Frame::AddWord',
);

=head2 cbox_rel

A combobox that allows to choose the type of relation to add

=cut

has cbox_rel => (
    is         => 'ro',
    isa        => 'Wx::ComboBox',
    lazy_build => 1,
);

sub _build_cbox_rel {
    my ($self) = @_;

    my $cbox
        = Wx::ComboBox->new(shift, wxID_ANY, undef, wxDefaultPosition,
        [110, -1], [], wxCB_DROPDOWN | wxCB_READONLY,
        wxDefaultValidator);

    my $rel_type_rs = Database->schema->resultset('RelType')->search({}, {});
    while (my $dbix_rel_type = $rel_type_rs->next) {
        $cbox->Append($dbix_rel_type->name, $dbix_rel_type->rel_type);
    }
    $cbox->SetStringSelection('Translation');

    return $cbox;
}

=head2 btn_additem

TODO add description

=cut

has btn_additem => (
    is      => 'ro',
    isa     => 'Wx::Button',
    lazy    => 1,
    default => sub {
        Wx::Button->new(shift, wxID_ANY, '+', wxDefaultPosition,
            wxDefaultSize)
    },
);

=head2 vbox_item

TODO add description

=cut

has vbox_item => (
    is      => 'ro',
    isa     => 'ArrayRef',
    lazy    => 1,
    default => sub { [] },
);

=head2 hbox_add

TODO add description

=cut

has hbox_add => (
    is         => 'ro',
    isa        => 'Wx::BoxSizer',
    lazy_build => 1,
);

sub _build_hbox_add {
    my $self = shift;

    my $hbox_add = Wx::BoxSizer->new(wxHORIZONTAL);
    $hbox_add->Add($self->cbox_rel,    wxALIGN_LEFT | wxRIGHT, 5);
    $hbox_add->Add($self->btn_additem, wxALIGN_LEFT | wxRIGHT, 5);

    return $hbox_add;
}

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
    $vbox->Add($self->hbox_add, 0, wxALIGN_LEFT | wxRIGHT, 5);

    return $vbox;
}

=head2 word_translations

TODO add description

=cut

has word_translations => (
    is      => 'ro',
    isa     => 'ArrayRef',
    lazy    => 1,
    default => sub { [] },
);

=head1 METHODS

=head2 keybind

TODO add description

=cut

sub keybind {
    my ($self, $event) = @_;

    my $key_modifiers = $event->GetModifiers();
    my $key_code = $event->GetKeyCode();

    if ($key_modifiers == (wxMOD_CONTROL | wxMOD_SHIFT)) {
        given ($key_code) {
            when ([WXK_UP, WXK_DOWN]) {
                my $current_id = $self->_get_focused_tr_phrase_id();
                my $cbox = $self->word_translations->[$current_id]{cbox_pos};
                my $new_index
                    = $cbox->GetSelection + (($key_code == WXK_UP) ? -1 : 1);
                if ($new_index < 0) { $new_index = $cbox->GetCount - 1 }
                elsif ($new_index >= $cbox->GetCount) { $new_index = 0 }
                $cbox->SetSelection($new_index);
            }
        }
        return;
    }

    return if $key_modifiers != wxMOD_CONTROL;

    given ($key_code) {
        # Ctrl+"+" or Ctrl+"+" on NumPad
        when ([WXK_ADD, WXK_NUMPAD_ADD]) {
            $self->add_item();
        }
        # Ctrl+"-" or Ctrl+"-" on NumPad
        when ([WXK_SUBTRACT, WXK_NUMPAD_SUBTRACT]) {
            my $focused_phrase_id = $self->_get_focused_tr_phrase_id();
            return if !defined $focused_phrase_id;
            $self->del_item($focused_phrase_id);

            if ($self->translation_count <= 0) {

                # if there's no any translation item, set a focus on word_src
                # field and go away
                $self->parent->word_src->SetFocus();
                return;
            }

            # focus the next item
            my $next_phrase_id = $focused_phrase_id;
            my $next_tr_item;
            do {
                $next_phrase_id++;
                if ($next_phrase_id >= $self->translation_count) {
                    $next_phrase_id -= 2;
                } elsif ($next_phrase_id == $focused_phrase_id) {
                    return
                }
                $next_tr_item = $self->word_translations->[$next_phrase_id];
            } while (!defined $next_tr_item);
            $next_tr_item->{word}->SetFocus();
        }
        # Ctrl+"H" or Ctrl+"h"
        when ([ord('H'), ord('h')]) {
            $self->toggle_note( $self->_get_focused_tr_phrase_id() );
        }
        when ([WXK_UP, WXK_DOWN]) {
            my $count = $self->translation_count;
            return if $count <= 1;

            my $current_id = $self->_get_focused_tr_phrase_id();
            my $id = $current_id;
            my $inc = ($_ == WXK_UP) ? -1 : 1;

            $id += $inc;
            while (!$self->word_translations->[$id]) {
                $id += $inc;
                if    ($id < 0)      { $id = $count }
                elsif ($id > $count) { $id = 0 }
                return if $id == $current_id;
            }

            $self->word_translations->[$id]{word}->SetFocus()
                if $self->word_translations->[$id];
        }
    }
}

sub _find_phrase_id_by_widget {
    my ($self, $widget) = @_;

    for my $translation_item (grep { defined } @{ $self->word_translations })
    {
        for my $tr_widget (
            $translation_item->{word}->GetTextCtrl,
            $translation_item->{note}
           )
        {
            # scalar of an object returns a string like
            # Wx::TextCtrl=HASH(0x3af9fe0)
            return $translation_item->{id}
                if scalar $tr_widget eq scalar $widget;
        }
    }
}

# returns an index of element in word_translations
sub _get_focused_tr_phrase_id {
    my ($self) = @_;

    my $widget = Wx::Window::FindFocus();
    return if ref $widget ne 'Wx::TextCtrl';

    given (ref $widget->GetParent) {
        # word
        when ('Wx::ComboCtrl') {
            return $widget->GetLabel;
        }
        # note
        when ('Dict::Learn::Frame::AddWord::LinkedPhrases') {
            return $self->_find_phrase_id_by_widget($widget);
        }
    }
}

sub _scroll_to_bottom {
    my ($self) = @_;

    my $y_unit = ($self->GetScrollPixelsPerUnit())[1];
    my $height = ($self->GetVirtualSize())[1];

    $self->Scroll(0, int($height / $y_unit));
}

sub _guess_part_of_speech {
    my ($self) = @_;

    my $part_of_speech_name;

    given ($self->parent->word_src->GetValue()) {
        when (/ (?:ing|ness) $/x) {
            $part_of_speech_name = 'noun';
        }
        when (/ (?:ful|able|ed|ious) $/x) {
            $part_of_speech_name = 'adjective';
        }
        when (/ (?:ly|less) $/x) {
            $part_of_speech_name = 'adverb';
        }
    }

    return $self->get_partofspeech_id($part_of_speech_name);
}

sub _get_previous_part_of_speech {
    my ($self) = @_;

    my $id = $#{ $self->vbox_item };

    if ($id > 0 and my $prev_item = $self->word_translations->[$id - 1]) {
        return
            unless defined $prev_item->{cbox_pos}
            and ref $prev_item->{cbox_pos} eq 'Wx::ComboBox'
            and $prev_item->{cbox_pos}->GetSelection >= 0;

        return $prev_item->{cbox_pos}->GetSelection;
    }
}

=head2 set_status_text

Set the status in the bottom's statusbar

=cut

sub set_status_text {
    my ($self, $status_text) = @_;

    $self->parent->parent->status_bar->SetStatusText($status_text);
}

=head2 make_item

TODO add description

=cut

sub make_item {
    my ($self, $word_id, $ro) = @_;

    my $vbox = Wx::BoxSizer->new(wxVERTICAL);
    my $hbox = Wx::BoxSizer->new(wxHORIZONTAL);
    push @{ $self->vbox_item } => $vbox;

    my $id = $#{ $self->vbox_item };

    my %translation_item = (
        word_id  => $word_id,
        id       => $id,
        cbox_pos => Wx::ComboBox->new(
            $self, wxID_ANY,
            undef, wxDefaultPosition,
            [110, -1], [$self->import_partofspeech],
            wxCB_DROPDOWN | wxCB_READONLY, wxDefaultValidator
        ),
        popup => Dict::Learn::Widget::WordList->new(),
        word  => Wx::ComboCtrl->new(
            $self,         wxID_ANY,
            '',            wxDefaultPosition,
            wxDefaultSize, wxCB_DROPDOWN,
            wxDefaultValidator
        ),
        note => Wx::TextCtrl->new($self, wxID_ANY, '', wxDefaultPosition,
            wxDefaultSize),
        btnm => Wx::Button->new(
            $self, wxID_ANY, '-', wxDefaultPosition, [40, -1]
        ),
        btnn => Wx::Button->new(
            $self, wxID_ANY, 'n', wxDefaultPosition, [40, -1]
        ),
        parent_vbox => $vbox,
        parent_hbox => $hbox,
    );

    $self->word_translations->[$id] = \%translation_item;

    $translation_item{word}->GetTextCtrl->SetLabel($id);
    $translation_item{word}
        ->SetPopupControl($translation_item{popup});

    EVT_BUTTON(
        $self, $translation_item{btnm},
        sub { $self->del_item($id) }
    );

    EVT_BUTTON(
        $self, $translation_item{btnn},
        sub { $self->toggle_note($id) }
    );

    my $part_of_speach_selection
        = $id == 0
        # Try to guess the part-of-speech based on word's suffix
        ? $self->_guess_part_of_speech()
        # Duplicate a previous part-of-speech in a next item
        : $self->_get_previous_part_of_speech() // 0;

    $translation_item{cbox_pos}->SetSelection($part_of_speach_selection);

    $hbox->Add($translation_item{cbox_pos}, 0, wxALL, 0);
    $hbox->Add($translation_item{word}, 4, wxALL, 0);
    $hbox->Add($translation_item{btnn}, 0, wxALL, 0);
    $hbox->Add($translation_item{btnm}, 0, wxALL, 0);

    $vbox->Add($hbox, 0, wxEXPAND, 0);
    $vbox->Add($translation_item{note}, 0, wxEXPAND, 0);

    if ($ro) {
        $translation_item{word}->GetTextCtrl->SetEditable(0);
        $translation_item{word}->GetPopupWindow->Disable;
        $translation_item{edit}
            = Wx::Button->new($self, wxID_ANY, 'e', wxDefaultPosition,
            [40, -1]);

        EVT_BUTTON(
            $self, $translation_item{edit},
            sub { $self->edit_word_as_new($id) }
        );
        $hbox->Add($translation_item{edit}, 0, wxALL, 0);
    }

    # Set focus on newly created word field
    $translation_item{word}->GetTextCtrl->SetFocus();
    $translation_item{note}->Hide();

    return \%translation_item;
}

=head2 add_item

TODO add description

=cut

sub add_item {
    my ($self, %params) = @_;

    my $translation_item
        = $self->make_item($params{word_id}, $params{read_only});

    my @children = $self->vbox->GetChildren;
    $self->vbox->Insert($#children || 0,
        $translation_item->{parent_vbox}, 0, wxALL | wxEXPAND, 0);

    # fill out the fields

    my $partofspeech_id;
    if (defined $params{partofspeech_id}) {
        $partofspeech_id = $params{partofspeech_id};
    } elsif ($params{partofspeech}) {
        $partofspeech_id = $self->get_partofspeech_id($params{partofspeech});
    }
    $translation_item->{cbox_pos}->SetSelection($partofspeech_id)
        if defined $partofspeech_id;

    $translation_item->{word}->SetValue($params{word}) if $params{word};
    $translation_item->{word}->SetLabel($params{word_id}) if $params{word_id};

    my $note = '';
    $note = "( $params{category} )" if $params{category};
    $note .= ($note ? ' ' : '') . $params{note} if $params{note};
    if ($note) {
        $translation_item->{note}->Show();
        $translation_item->{note}->SetValue($note);
    }

    $self->vbox->FitInside($self);
    $self->vbox->Layout();
    $self->_scroll_to_bottom();

    return $translation_item;
}

=head2 del_item

TODO add description

=cut

sub del_item {
    my ($self, $id) = @_;

    die "There's no translation with such index"
        unless exists $self->word_translations->[$id];

    my $phrase = $self->word_translations->[$id]{word}->GetValue();

    for (keys %{ $self->word_translations->[$id] }) {
        my $ref = ref $self->word_translations->[$id]{$_};
        next
            if !$ref                  # next if a value is a regular scalar
            || $ref eq 'Wx::BoxSizer' # BoxSizer instances we'll delete later
            || !defined $self->word_translations->[$id]{$_};

        $self->word_translations->[$id]{$_}->Destroy()
            if $self->word_translations->[$id]{$_}->can('Destroy');
        delete $self->word_translations->[$id]{$_};
    }
    $self->vbox->Detach($self->vbox_item->[$id])
        if defined $self->vbox_item->[$id];
    $self->Layout();
    delete $self->vbox_item->[$id];
    delete $self->word_translations->[$id]{parent_vbox};
    delete $self->word_translations->[$id]{parent_hbox};
    delete $self->word_translations->[$id];

    $self->set_status_text(
        qq{Translation phrase "$phrase" has just been deleted})
        if $phrase;

    return $self;
}

=head2 toggle_note

Show/hide a note field for given translation

=cut

sub toggle_note {
    my ($self, $id) = @_;

    die "There's no translation with such index"
        unless exists $self->word_translations->[$id];

    my $note = $self->word_translations->[$id]{note};
    if ($note->IsShown) {
        $note->Hide();
        $self->word_translations->[$id]{word}->SetFocus();
    } else {
        $note->Show();
        $note->SetFocus();
    }
    $self->vbox->Layout();
}

=head2 edit_word_as_new

TODO add description

=cut

sub edit_word_as_new {
    my ($self, $word_id) = @_;

    # set editable
    $self->word_translations->[$word_id]{word}->SetEditable(1);

    # remove example id
    $self->word_translations->[$word_id]{word_id} = undef;

    # remove edit button
    $self->word_translations->[$word_id]{edit}->Destroy();
    $self->word_translations->[$word_id]{parent_hbox}
        ->Remove($self->word_translations->[$word_id]{edit});
    delete $self->word_translations->[$word_id]{edit};

    return $self;
}

=head2 for_each

TODO add description

=cut

sub for_each($$) {
    my ($self, $cb) = @_;

    for my $translation_item (grep { defined } @{ $self->word_translations }) {
        $cb->($self, $translation_item);
    }
}

=head2 remove_all

TODO add description

=cut

sub remove_all {
    my $self = shift;

    for (grep { defined } @{$self->word_translations}) {
        $self->del_item($_->{id});
    }
}

=head2 translation_count

TODO add description

=cut

sub translation_count { scalar @{$_[0]->word_translations} }

=head2 add

TODO add description

=cut

sub add {
    my ($self, $word, $partofspeech) = @_;

    $self->add_item(
        word         => $word->{word},
        partofspeech => $partofspeech,
        map { $word->{$_} ? ($_ => $word->{$_}) : () } (qw(category note)),
    );
}

=head2 import_partofspeech

TODO add description

=cut

sub import_partofspeech {
    my $self = shift;

    map { $_->{name_orig} }
        Database->schema->resultset('PartOfSpeech')->select();
}

=head2 get_partofspeech_id

TODO add description

=cut

sub get_partofspeech_id {
    my ($self, $name) = @_;

    for (Database->schema->resultset('PartOfSpeech')
        ->select(name => $name))
    {
        return $_->{partofspeech_id};
    }
}

sub FOREIGNBUILDARGS {
    my ($class, @args) = @_;
    return @args;
}

sub BUILDARGS {
    my ($class, $parent) = @_;
    return { parent => $parent };
}

sub BUILD {
    my ($self, @args) = @_;

    ### main layout  
    $self->SetSizerAndFit($self->vbox);
    $self->Layout();

    # events
    EVT_BUTTON($self, $self->btn_additem, sub { $self->add_item });
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

