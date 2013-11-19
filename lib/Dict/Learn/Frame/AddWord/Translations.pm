package Dict::Learn::Frame::AddWord::Translations 0.1;

use Wx qw[:everything];
use Wx::Event qw[:everything];

use Moose;
use MooseX::NonMoose;
extends 'Wx::ScrolledWindow';

use Carp qw[croak confess];
use Data::Printer;
use List::Util qw(first);

use Database;
use Dict::Learn::Combo::WordList;

use common::sense;

=item btn_additem

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

=item vbox_item

=cut

has vbox_item => (
    is      => 'ro',
    isa     => 'ArrayRef',
    lazy    => 1,
    default => sub { [] },
);

=item hbox_add

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
    $vbox->Add($self->hbox_add, 0, wxALIGN_LEFT | wxRIGHT, 5);

    return $vbox;
}

=item word_translations

=cut

has word_translations => (
    is      => 'ro',
    isa     => 'ArrayRef',
    lazy    => 1,
    default => sub { [] },
);

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
        popup => Dict::Learn::Combo::WordList->new(),
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

    my $part_of_speach_selection = 0;
    if ($id > 0 and my $prev_item = $self->word_translations->[$id - 1]) {
        return unless defined $prev_item->{cbox}
            and ref $prev_item->{cbox} eq 'Wx::ComboBox'
            and $prev_item->{cbox}->GetSelection >= 0;

        $part_of_speach_selection = $prev_item->{cbox}->GetSelection;
    }
    $translation_item{cbox}->SetSelection($part_of_speach_selection);

    $hbox->Add($translation_item{cbox}, 0, wxALL, 0);
    $hbox->Add($translation_item{word}, 4, wxALL, 0);
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

    return \%translation_item;
}

sub add_item {
    my ($self, %params) = @_;

    my $translation_item
        = $self->make_item($params{word_id}, $params{read_only});

    my @children = $self->vbox->GetChildren;
    $self->vbox->Insert($#children || 0,
        $translation_item->{parent_vbox}, 1, wxALL | wxGROW, 0);
    $self->vbox->FitInside($self);
    $self->vbox->Layout();

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
    $translation_item->{note}->SetValue($note) if $note;

    return $translation_item;
}

sub del_item {
    my ($self, $id) = @_;

    for (qw[ cbox word btnm btnp edit note ]) {
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

    return $self;
}

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

sub for_each($$) {
    my ($self, $cb) = @_;

    for my $translation_item (grep { defined } @{ $self->word_translations }) {
        $cb->($self, $translation_item);
    }
}

sub remove_all {
    my $self = shift;

    for (@{$self->word_translations}) {
        $self->del_item($_->{id});
        delete $self->word_translations->[$_->{id}];
    }
}

sub translation_count { scalar @{$_[0]->word_translations} }

sub add {
    my ($self, $word, $partofspeech) = @_;

    $self->add_item(
        word         => $word->{word},
        partofspeech => $partofspeech,
        map { $word->{$_} ? ($_ => $word->{$_}) : () } (qw(category note)),
    );
}

sub import_partofspeech {
    my $self = shift;

    map { $_->{name_orig} }
        Database->schema->resultset('PartOfSpeech')->select();
}

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
    my ($class, @args) = @_;
    return { };
}

sub BUILD {
    my ($self, @args) = @_;

    ### main layout  
    $self->SetSizer($self->vbox);
    $self->Layout();
    $self->vbox->Fit($self);

    # events
    EVT_BUTTON($self, $self->btn_additem, sub { $self->add_item });

    EVT_KEY_UP($self, \&keybind);
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

