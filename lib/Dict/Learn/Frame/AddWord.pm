package Dict::Learn::Frame::AddWord 0.1;

use Wx qw[:everything];
use Wx::Event qw[:everything];

use Moose;
use MooseX::NonMoose;
extends 'Wx::Panel';

use Carp qw[croak confess];
use Data::Printer;

use Database;
use Dict::Learn::Dictionary;
use Dict::Learn::Translate;
use Dict::Learn::Frame::AddWord::Translations;

use common::sense;

=item item_id

=cut

has item_id => (
    is      => 'rw',
    isa     => 'Int',
    clearer => 'clear_item_id',
);

=item enable

=cut

has enable => (
    is      => 'rw',
    isa     => 'Bool',
    default => sub { 1 },
);

=item edit_origin

=cut

has edit_origin => (
    is        => 'rw',
    isa       => 'HashRef',
    predicate => 'has_edit_origin',
    clearer   => 'clear_edit_origin',
);

=item parent

=cut

has parent => (
    is  => 'ro',
    isa => 'Dict::Learn::Frame',
);

=item word_note

=cut

has word_note => (
    is      => 'ro',
    isa     => 'Wx::TextCtrl',
    default => sub {
        Wx::TextCtrl->new(shift, wxID_ANY, '', wxDefaultPosition,
            wxDefaultSize, wxTE_MULTILINE)
    },
);

=item word_src

=cut

has word_src => (
    is      => 'ro',
    isa     => 'Wx::TextCtrl',
    lazy    => 1,
    default => sub {
        Wx::TextCtrl->new(shift, wxID_ANY, '', wxDefaultPosition,
            wxDefaultSize, wxTE_MULTILINE)
    },
);

=item word2_src

=cut

has word2_src => (
    is         => 'ro',
    isa        => 'Wx::TextCtrl',
    lazy_build => 1,
);

sub _build_word2_src {
    my $self = shift;

    my $word2 = Wx::TextCtrl->new($self, wxID_ANY, '', wxDefaultPosition,
        wxDefaultSize);
    $word2->Enable(0);

    return $word2;
}

=item word3_src

=cut

has word3_src => (
    is         => 'ro',
    isa        => 'Wx::TextCtrl',
    lazy_build => 1,
);

sub _build_word3_src {
    my $self = shift;

    my $word3 = Wx::TextCtrl->new($self, wxID_ANY, '', wxDefaultPosition,
        wxDefaultSize);
    $word3->Enable(0);

    return $word3;
}

=item cb_irregular

=cut

has cb_irregular => (
    is      => 'ro',
    isa     => 'Wx::CheckBox',
    lazy    => 1,
    default => sub {
        Wx::CheckBox->new(shift, wxID_ANY, 'Irregular verb',
            wxDefaultPosition, wxDefaultSize, wxCHK_2STATE,
            wxDefaultValidator)
    },
);

=item vbox_src

=cut

has vbox_src => (
    is         => 'ro',
    isa        => 'Wx::BoxSizer',
    lazy_build => 1,
);

sub _build_vbox_src {
    my $self = shift;

    my $vbox_src = Wx::BoxSizer->new(wxVERTICAL);
    $vbox_src->Add($self->word_src,     2, wxGROW | wxEXPAND | wxBOTTOM, 5);
    $vbox_src->Add($self->cb_irregular, 1, wxALIGN_LEFT | wxBOTTOM,      5);
    $vbox_src->Add($self->word2_src,    1, wxGROW | wxBOTTOM,            5);
    $vbox_src->Add($self->word3_src,    1, wxGROW | wxBOTTOM,            5);

    return $vbox_src;
}

=item btn_add_word

=cut

has btn_add_word => (
    is      => 'ro',
    isa     => 'Wx::Button',
    lazy    => 1,
    default => sub {
        Wx::Button->new(shift, wxID_ANY, 'Add', wxDefaultPosition,
            wxDefaultSize)
    },
);

=item btn_translate

=cut

has btn_translate => (
    is      => 'ro',
    isa     => 'Wx::Button',
    lazy    => 1,
    default => sub {
        Wx::Button->new(shift, wxID_ANY, 'Translate', wxDefaultPosition,
            wxDefaultSize)
    },
);

=item btn_clear

=cut

has btn_clear => (
    is      => 'ro',
    isa     => 'Wx::Button',
    lazy    => 1,
    default => sub {
        Wx::Button->new(shift, wxID_ANY, 'Clear', wxDefaultPosition,
            wxDefaultSize)
    },
);

=item btn_cancel

=cut

has btn_cancel => (
    is      => 'ro',
    isa     => 'Wx::Button',
    lazy    => 1,
    default => sub {
        Wx::Button->new(shift, wxID_ANY, 'Cancel', wxDefaultPosition,
            wxDefaultSize)
    },
);

=item hbox_btn

=cut

has hbox_btn => (
    is         => 'ro',
    isa        => 'Wx::BoxSizer',
    lazy_build => 1,
);

sub _build_hbox_btn {
    my $self = shift;

    my $hbox_btn = Wx::BoxSizer->new(wxHORIZONTAL);
    $hbox_btn->Add($self->btn_add_word, 0,
        wxBOTTOM | wxALIGN_LEFT | wxLEFT, 5);
    $hbox_btn->Add(
        $self->btn_translate, 0, wxBOTTOM | wxALIGN_LEFT | wxLEFT, 5);
    $hbox_btn->Add($self->btn_clear,  0, wxBOTTOM | wxALIGN_LEFT | wxLEFT, 5);
    $hbox_btn->Add($self->btn_cancel, 0, wxBOTTOM | wxALIGN_LEFT | wxLEFT, 5);

    return $hbox_btn;
}

=item translations

=cut

has translations => (
    is         => 'ro',
    isa        => 'Dict::Learn::Frame::AddWord::Translations',
    lazy_build => 1,
);

sub _build_translations {
    my $self = shift;

    my $translations = Dict::Learn::Frame::AddWord::Translations->new(
        $self, wxID_ANY, wxDefaultPosition, wxDefaultSize, wxVSCROLL
    );
    $translations->SetScrollbars(20, 20, 0, 0);

    return $translations;
}

=item hbox_words

=cut

has hbox_words => (
    is         => 'ro',
    isa        => 'Wx::BoxSizer',
    lazy_build => 1,
);

sub _build_hbox_words {
    my $self = shift;

    my $hbox_words = Wx::BoxSizer->new(wxHORIZONTAL);
    $hbox_words->Add($self->vbox_src, 2, wxALL | wxTOP,    5);
    $hbox_words->Add($self->translations, 4, wxALL | wxEXPAND, 5);

    return $hbox_words;
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
    $vbox->Add($self->hbox_words, 3, wxALL | wxEXPAND | wxGROW, 0);
    $vbox->Add($self->word_note,  1, wxALL | wxEXPAND | wxGROW, 5);
    $vbox->Add($self->hbox_btn,   0, wxALL | wxGROW,            5);

    return $vbox;
}

sub keybind {
    my ($self, $event) = @_;

    # It should respond to Ctrl+"W", Ctrl+"w", and Ctrl+Enter
    # so if Ctrl key isn't pressed, go away
    return if $event->GetModifiers() != wxMOD_CONTROL;

    given ($event->GetKeyCode()) {
        # Ctrl+Enter + Ctrl+Enter on NumPad
        when([WXK_RETURN, WXK_NUMPAD_ENTER]) {
            $self->add();
        }
        # Ctrl+"W" and Ctrl+"w"
        when([ord('W'), ord('w')]) {
            $self->close_page();
        }
    }
}

# sub query_words {
#     my ($self, $id) = @_;

#     my $cb = $self->word_translations->[$id]{word};
#     my @words
#         = Database->schema->resultset('Word')
#         ->select(Dict::Learn::Dictionary->curr->{language_tr_id}{language_id},
#         $cb->GetValue());
#     $cb->Clear;
#     for (@words) {
#         $cb->Append($_->{word});
#     }
# }

sub check_word {
    my ($self, $event) = @_;

    my $word;
    unless (
        defined(
            $word
                = Database->schema->resultset('Word')->match(
                Dict::Learn::Dictionary->curr->{language_orig_id}
                    {language_id},
                $event->GetString
                )->first
        )
        )
    {
        $self->enable(1);
        $self->btn_add_word->SetLabel($self->item_id >= 0 ? 'Save' : 'Add');
        EVT_BUTTON($self, $self->btn_add_word, \&add);
    }
    else {
        if ($self->item_id >= 0) {
            return
                if $self->has_edit_origin
                and $self->edit_origin->{word} eq $event->GetString;
        }
        if ((my $word_id = $word->word_id) >= 0) {
            $self->enable(0);
            $self->btn_add_word->SetLabel(
                'Edit word "' . $self->word_src->GetValue . '"');
            EVT_BUTTON(
                $self,
                $self->btn_add_word,
                sub {
                    $self->enable(1);
                    $self->load_word(word_id => $word_id);
                    EVT_BUTTON($self, $self->btn_add_word, \&add);
                }
            );
        }
        else {
            $self->enable(1);
            $self->btn_add_word->SetLabel('Add');
            EVT_BUTTON($self, $self->btn_add_word, \&add);
        }
    }
    $self->enable_controls($self->enable);
}

sub add {
    my $self = shift;

    my $value = $self->word_src->GetValue();

    # remove leading and trailing spaces
    $value =~ s{ ^ \s+ }{}x;
    $value =~ s{ \s+ $ }{}x;

    my %params = (
        word => $value,
        note => $self->word_note->GetValue(),
        lang_id =>
            Dict::Learn::Dictionary->curr->{language_orig_id}{language_id},
        dictionary_id => Dict::Learn::Dictionary->curr_id,
    );
    if ($params{irregular} = $self->cb_irregular->IsChecked()) {
        $params{word2} = $self->word2_src->GetValue();
        $params{word3} = $self->word3_src->GetValue();
    }
    $self->translations->for_each(
        sub {
            my $translation_panel = pop;
            my %push_item = ( word_id => $translation_panel->{word_id} );
            if ($translation_panel->{word}) {
                $push_item{partofspeech}
                    = int($translation_panel->{cbox}->GetSelection());

                # `GetLabel` returns "" or value
                my $word_id = $translation_panel->{word}->GetLabel();
                $word_id = undef if $word_id eq '';
                if (defined $word_id and int $word_id >= 0) {
                    $push_item{word_id} = $word_id;
                    $push_item{word}    = 0;
                }
                else {
                    $push_item{word} = $translation_panel->{word}->GetValue();

                    # skip empty fields
                    next unless $push_item{word} =~ /^.+$/;
                }
                $push_item{note} = $translation_panel->{note}->GetValue();
                $push_item{lang_id}
                = Dict::Learn::Dictionary->curr->{language_tr_id}{language_id};
            }
            push @{$params{translate}} => \%push_item;
        }
    );
    if (defined $self->item_id
        and $self->item_id >= 0)
    {
        $params{word_id} = $self->item_id;
        Database->schema->resultset('Word')
            ->update_one(%params);
    }
    else {
        Database->schema->resultset('Word')->add_one(%params);
    }

    # Close the page after adding/editing the word
    $self->close_page();

    # TODO trigger an event informing that word list should be reloaded
    # $self->parent->p_search->lookup;

    return $self;
}

sub clear_fields {
    my $self = shift;

    $self->clear_item_id;
    $self->clear_edit_origin;
    $self->enable(1);
    $self->enable_controls($self->enable);

    $self->word_src->Clear;

    # irregular words
    $self->word2_src->Clear;
    $self->word3_src->Clear;
    $self->enable_irregular(0);

    $self->translations->for_each(
        sub {
            my $translation_item = pop;
            return unless defined $translation_item->{word};
            $translation_item->{cbox}->SetSelection(0);
            $translation_item->{word}->SetText('');
            $translation_item->{note}->Clear;
        }
    );
    $self->word_note->Clear;
}

sub load_word {
    my ($self, %params) = @_;

    my $word = Database->schema->resultset('Word')
        ->select_one($params{word_id});
    my @translate;
    for my $rel_word (@{$word->{rel_words}}) {
        next unless $rel_word->{word2_id} or $rel_word->{word2_id}{word_id};
        push @translate => {
            word_id         => $rel_word->{word2_id}{word_id},
            word            => $rel_word->{word2_id}{word},
            partofspeech_id => $rel_word->{partofspeech_id},
            note            => $rel_word->{note},
        };
    }
    $self->fill_fields(
        word_id         => $word->{word_id},
        word            => $word->{word},
        word2           => $word->{word2},
        word3           => $word->{word3},
        irregular       => $word->{irregular},
        partofspeech_id => $word->{partofspeech_id},
        note            => $word->{note},
        translate       => \@translate,
    );
    $self->btn_add_word->SetLabel('Save');
}

sub fill_fields {
    my ($self, %params) = @_;

    $self->clear_fields;
    $self->edit_origin(\%params);
    $self->item_id($params{word_id});
    $self->translations->remove_all;
    $self->word_src->SetValue($params{word});
    $self->enable_irregular($params{irregular});

    if ($params{irregular}) {
        $self->word2_src->SetValue($params{word2}) if $params{word2};
        $self->word3_src->SetValue($params{word3}) if $params{word3};
    }
    for my $word_tr (@{$params{translate}}) {
        $self->translations->add_item(
            word_id         => $word_tr->{word_id},
            read_only       => 1,
            word            => $word_tr->{word},
            note            => $word_tr->{note},
            partofspeech_id => $word_tr->{partofspeech_id},
        );
    }
    $self->word_note->SetValue($params{note});
}

sub translate_word {
    my $self = shift;

    my $res  = $self->parent->translator->do(
        'en' => 'uk',
        $self->word_src->GetValue()
    );
    p($res);
    my $limit = $self->translations->translation_count;
    if (keys %$res >= 1) {
        for my $meaning_group (keys %$res) {
            for my $partofspeech (keys %$res->{$meaning_group}) {
                next
                    if $partofspeech eq '_'
                    and ref $res->{$meaning_group}{$partofspeech} eq '';
                for my $words (@{$res->{$meaning_group}{$partofspeech}}) {
                    given (ref $words) {
                        when ('ARRAY') {
                            for my $word (@$words) {
                                $self->translations->add($word, $partofspeech);
                            }
                        }
                        when ('HASH') {
                            $self->translations->add($words, $partofspeech);
                        }
                    }
                }
            }
        }
    }
}

sub enable_irregular {
    my ($self, $is_checked) = @_;

    $self->cb_irregular->SetValue($is_checked);
    $self->word2_src->Enable($is_checked);
    $self->word3_src->Enable($is_checked);
}

sub toggle_irregular {
    my ($self, $event) = @_;

    $self->enable_irregular($event->IsChecked);
}

sub enable_controls($$) {
    my ($self, $is_enabled) = @_;

    $self->translations->btn_additem->Enable($is_enabled);
    $self->btn_clear->Enable($is_enabled);
    $self->word_note->Enable($is_enabled);
    $self->btn_translate->Enable($is_enabled);
    $self->translations->for_each(
        sub {
            my $translation_item = pop;
            return unless defined $translation_item->{word};
            for my $widget (qw(word note cbox btnm edit)) {
                next if !$translation_item->{$widget};
                $translation_item->{$widget}->Enable($is_enabled);
            }
        }
    );
}

sub close_page {
    my $self = shift;

    $self->clear_fields();
    $self->translations->remove_all();

    $self->parent->notebook->DeletePage(
        $self->parent->notebook->GetSelection()
    );
}

sub FOREIGNBUILDARGS {
    my ($class, $parent, @args) = @_;
    return @args;
}

sub BUILDARGS {
    my ($class, $parent) = @_;
    return { parent => $parent };
}

sub BUILD {
    my ($self, @args) = @_;

    ### main layout  
    $self->SetSizer($self->vbox);
    $self->Layout();
    $self->vbox->Fit($self);

    # events
    EVT_BUTTON($self, $self->btn_add_word,   \&add);
    EVT_BUTTON($self, $self->btn_clear,      \&clear_fields);
    EVT_BUTTON($self, $self->btn_translate,  \&translate_word);
    EVT_BUTTON($self, $self->btn_cancel,     \&close_page);
    EVT_CHECKBOX($self, $self->cb_irregular, \&toggle_irregular);
    EVT_TEXT($self, $self->word_src,         \&check_word);

    EVT_KEY_UP($self, \&keybind);

    # Set focus on word field
    $self->word_src->SetFocus();

    $self;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
