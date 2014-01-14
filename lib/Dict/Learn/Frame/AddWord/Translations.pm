package Dict::Learn::Frame::AddWord::Translations;

use Wx qw[:everything];
use Wx::Event qw[:everything];

use Moose;
use MooseX::NonMoose;
extends 'Wx::ScrolledWindow';

use Carp qw[croak confess];
use Data::Printer;
use List::Util qw(first);

use Database;
use Dict::Learn::Widget::WordList;

use common::sense;

=head1 NAME

Dict::Learn::Frame::AddWord::Translations

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

    # It should respond to Ctrl+"+" and Ctrl+"-"
    # so if Ctrl key isn't pressed, go away
    return if $event->GetModifiers() != wxMOD_CONTROL;

    given ($event->GetKeyCode()) {
        # Ctrl+"+" or Ctrl+"+" on NumPad
        when ([WXK_ADD, WXK_NUMPAD_ADD]) {
            $self->add_item();
        }
        # Ctrl+"-" or Ctrl+"-" on NumPad
        when ([WXK_SUBTRACT, WXK_NUMPAD_SUBTRACT]) {
            if (my $last_word_obj
                = first { defined $_->{cbox} }
                reverse @{ $self->word_translations })
            {
                $self->del_item($last_word_obj->{id});
            }
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
            unless defined $prev_item->{cbox}
            and ref $prev_item->{cbox} eq 'Wx::ComboBox'
            and $prev_item->{cbox}->GetSelection >= 0;

        return $prev_item->{cbox}->GetSelection;
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
        word_id => $word_id,
        id      => $id,
        cbox    => Wx::ComboBox->new(
            $self, wxID_ANY,
            undef, wxDefaultPosition,
            [110, -1], [$self->import_partofspeech],
            wxCB_DROPDOWN | wxCB_READONLY, wxDefaultValidator
        ),
        popup => Dict::Learn::Widget::WordList->new(),
        word => Wx::ComboCtrl->new(
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

    $translation_item{cbox}->SetSelection($part_of_speach_selection);

    $hbox->Add($translation_item{cbox}, 0, wxALL, 0);
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
    $translation_item->{cbox}->SetSelection($partofspeech_id)
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

    for (qw[ cbox word btnm btnp btnn edit note ]) {
        next unless defined $self->word_translations->[$id]{$_};
        $self->word_translations->[$id]{$_}->Destroy();
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
    $note->Show(!$note->IsShown);
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

