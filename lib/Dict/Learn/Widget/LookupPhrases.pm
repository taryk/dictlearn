package Dict::Learn::Widget::LookupPhrases;

use Wx qw[:everything];
use Wx::Event qw[:everything];

use Moose;
use MooseX::NonMoose;
extends 'Wx::Panel';

use Const::Fast;

use Database;
use Dict::Learn::Dictionary;

use Data::Printer;

use common::sense;

const my @LANG_COL => (1, 3);
const my $LAST_SEARCH_HISTORY_SIZE => 20;

=head1 NAME

Dict::Learn::Widget::LookupPhrases

=head1 DESCRIPTION

TODO add description

=head1 ATTRIBUTES

=head2 parent

Link to the parent object

=cut

has parent => (
    is  => 'ro',
    isa => 'Wx::Window',
);

=head2 options

Additional customization of this widget

=head3 parameters

=over

=item translated_only

Boolean. Applies "/translated" filter by default and disallows any other filters.

=item buttons

Boolean. Determines whether to show or hide the buttons near to lookup field.

=back

=cut

has options => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub {
        {
            translated_only => 0,
            buttons         => 1,
        }
    }
);

=head2 lookup_field

TODO add description

=cut

has lookup_field => (
    is         => 'ro',
    isa        => 'Wx::ComboBox',
    lazy_build => 1,
);

sub _build_lookup_field {
    my $self     = shift;

    my $lookup_field
        = Wx::ComboBox->new($self, wxID_ANY, '', wxDefaultPosition,
        wxDefaultSize, [], 0, wxDefaultValidator);
    EVT_TEXT_ENTER($self, $lookup_field, \&lookup);

    return $lookup_field;
}

=head2 btn_lookup

TODO add description

=cut

has btn_lookup => (
    is         => 'ro',
    isa        => 'Wx::Button',
    lazy_build => 1,
);

sub _build_btn_lookup {
    my $self = shift;

    my $btn_lookup = Wx::Button->new($self, wxID_ANY, '#', [20, 20]);
    EVT_BUTTON($self, $btn_lookup, \&lookup);

    return $btn_lookup;
}

=head2 btn_reset

TODO add description

=cut

has btn_reset => (
    is         => 'ro',
    isa        => 'Wx::Button',
    lazy_build => 1,
);

sub _build_btn_reset {
    my $self = shift;

    my $btn_reset = Wx::Button->new($self, wxID_ANY, 'Reset', [20, 20]);
    EVT_BUTTON($self, $btn_reset, \&reset);

    return $btn_reset;
}

=head2 btn_addword

TODO add description

=cut

has btn_addword => (
    is         => 'ro',
    isa        => 'Wx::Button',
    lazy_build => 1,
);

sub _build_btn_addword {
    my $self = shift;

    my $btn_addword = Wx::Button->new($self, wxID_ANY, 'Add', [20, 20]);
    EVT_BUTTON($self, $btn_addword, \&add_word);

    return $btn_addword;
}

=head2 lookup_hbox

TODO add description

=cut

has lookup_hbox => (
    is         => 'ro',
    isa        => 'Wx::BoxSizer',
    lazy_build => 1,
);

sub _build_lookup_hbox {
    my $self = shift;

    my $hbox = Wx::BoxSizer->new(wxHORIZONTAL);
    $hbox->Add($self->lookup_field, 1, wxEXPAND);

    if ($self->options->{buttons}) {
        $hbox->Add($self->btn_lookup,   0, wxALIGN_RIGHT);
        $hbox->Add($self->btn_reset,    0, wxALIGN_RIGHT);
        $hbox->Add($self->btn_addword,  0, wxALIGN_RIGHT);
    }

    return $hbox;
}

=head2 phrase_table

TODO add description

=cut

has phrase_table => (
    is         => 'ro',
    isa        => 'Wx::ListCtrl',
    lazy_build => 1,
);

sub _build_phrase_table {
    my $self = shift;

    my $phrase_table
        = Wx::ListCtrl->new($self, wxID_ANY, wxDefaultPosition, wxDefaultSize,
        wxLC_REPORT | wxLC_HRULES | wxLC_VRULES);
    $phrase_table->InsertColumn(0,          'id',   wxLIST_FORMAT_LEFT, 50);
    $phrase_table->InsertColumn($LANG_COL[0], 'Eng',  wxLIST_FORMAT_LEFT, 200);
    $phrase_table->InsertColumn(2,          'pos',  wxLIST_FORMAT_LEFT, 35);
    $phrase_table->InsertColumn($LANG_COL[1], 'Ukr',  wxLIST_FORMAT_LEFT, 200);
    $phrase_table->InsertColumn(4,          'note', wxLIST_FORMAT_LEFT, 200);
    $phrase_table->InsertColumn(5,       'created', wxLIST_FORMAT_LEFT, 150);

    return $phrase_table;
}

=head2 lookup_hbox

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
    $vbox->Add($self->lookup_hbox,  0, wxEXPAND);
    $vbox->Add($self->phrase_table, 1, wxEXPAND);

    return $vbox;
}

=head1 METHODS

=head2 _get_word_forms

TODO add description

=cut

sub _get_word_forms {
    my ($self, $word) = @_;

    # return an empty arrayref if a word is empty
    return [] unless $word;

    my @word_forms = ($word);

    # try other 'be' form
    # TODO also wasn't | was not | weren't | were not | is not | isn't
    my @be = qw(be was were is are);
    for my $be_form (@be) {
        next if $word !~ m{ \b $be_form \b }xi;
        push @word_forms, map {
            $word =~ s{\b$be_form\b}{$_}gir
        } grep { $_ ne $be_form } @be;
        last;
    }

    # TODO dashes

    return \@word_forms if $word =~ m{\s};

    my @suffixes = qw(ed ing ly ness less able es s);

    for my $suffix (@suffixes) {
        next if $word !~ m{ ^ (?<word>\w+) $suffix $ }x;
        push @word_forms, $+{word};
        last;
    }

    return \@word_forms;
}

=head2 _strip_spaces

Removes the whitespaces at the beginning and at the end of a string

=cut

sub _strip_spaces {
    my ($self, $phrase) = @_;

    # remove leading and trailing spaces
    $phrase =~ s{ ^ \s+ }{}x;
    $phrase =~ s{ \s+ $ }{}x;

    return $phrase;
}

=head2 set_status_text

TODO add description

=cut

sub set_status_text {
    my ($self, $status_text) = @_;

    $self->parent->parent->status_bar->SetStatusText($status_text);
}

=head2 lookup

TODO add description

=cut

sub lookup {
    my ($self, $event) = @_;

    state $previous_value;

    my $value = $self->lookup_field->GetValue;
    my $lang_id
        = Dict::Learn::Dictionary->curr->{language_orig_id}{language_id};

    my (%args, @result);
    if ($value =~ m{^ / (?<filter> \!? [\w=]+ ) $}x) {
        given ($+{filter}) {
            when([qw(all)]) { %args = () }
            when([qw(untranslated !untranslated translated irregular)]) {
                my $filter = $+{filter};
                $filter = 'translated' if $filter eq '!untranslated';
                %args = (filter => $filter);
            }
            when([qw(words phrases phrasal_verbs idioms)]) {
                # TODO return only words
                # it requires to have some kind of tags, which can be filtered by
                $self->set_status_text(
                    sprintf 'Filter "/%s" is not implemented at the moment ',
                    $+{filter}
                );
                return;
            }
            when(m{^ partofspeech = (?<partofspeech> \w+ ) $}x) {
                %args = (partofspeech => $+{partofspeech});
            }
            default {
                $self->set_status_text(
                    sprintf 'Unknown filter: "/%s"', $+{filter});
                return;
            }
        }
    } else {
        %args = (
            $value
                ? (word => $self->_get_word_forms($value))
                : (rows => 1_000)
        );
    }

    if ($self->options->{translated_only}) {
        if ($args{filter}) {
            $self->set_status_text(
                sprintf q{Filter "/%s" isn't allowed here}, $args{filter});
            return;
        }
        $args{filter} = 'translated';
    }

    @result = Database->schema->resultset('Word')
        ->find_ones_cached(%args, lang_id => $lang_id);

    $self->phrase_table->DeleteAllItems();
    my $item_id;
    for my $item (@result) {
        # there can be undefined items we should ignore
        next unless defined $item;
        my $id = $self->phrase_table->InsertItem(
            # InsertItem method always inserts an item at the first position
            # so set the position explicitly
            do {
                my $list_item = Wx::ListItem->new;
                $list_item->SetId($item_id++);
                $list_item
            }
        );

        my $word
            = $item->{is_irregular}
            ? join(' / ' => $item->{word_orig}, $item->{word2}, $item->{word3})
            : $item->{word_orig};
        $self->phrase_table->SetItem($id, 0,          $item->{word_id});
        $self->phrase_table->SetItem($id, $LANG_COL[0], $word);
        $self->phrase_table->SetItem($id, 2,     $item->{partofspeech} // '');
        $self->phrase_table->SetItem($id, $LANG_COL[1], $item->{word_tr} // '');
        $self->phrase_table->SetItem($id, 4,          $item->{note});
        $self->phrase_table->SetItem($id, 5,          $item->{cdate});

    }
    $self->select_first_item;

    my $records_count = scalar @result;

    # go on only if previous and current value aren't the same
    if (   $previous_value ne $value
           # $value should contain at least one letter
        && $value =~ m{ [a-z] }ix)
    {
        Database->schema->resultset('SearchHistory')->create(
            {
                text          => $self->_strip_spaces($value),
                dictionary_id => Dict::Learn::Dictionary->curr_id,
                results_count => $records_count,
            }
        );

        # TODO just add element to the lookup combobox w/o full reloading
        $self->load_search_history(Dict::Learn::Dictionary->curr_id);
    }
    $previous_value = $value;

    # Show how many records have been selected
    $self->set_status_text($records_count > 0
        ? "$records_count records selected"
        : 'No records selected');
}

=head2 select_first_item

TODO add description

=cut

sub select_first_item {
    my $self = shift;

    $self->phrase_table->SetItemState(
        $self->phrase_table->GetNextItem(
            -1, wxLIST_NEXT_ALL, wxLIST_STATE_DONTCARE
        ),
        wxLIST_STATE_SELECTED,
        wxLIST_STATE_SELECTED
    );
}

=head2 reset

TODO add description

=cut

sub reset {
    my ($self) = @_;

    $self->lookup_field->SetValue('');
    $self->lookup();
}

=head2 add_word

TODO add description

=cut

sub add_word {
    my ($self) = @_;

    my $add_word_page = $self->parent->parent->p_addword;
    $add_word_page->set_word($self->lookup_field->GetValue);
    $self->parent->parent->new_page($add_word_page, 'Add');
}

=head2 load_search_history

(Re)load the latest n unique words/phrases which were looked for
into the lookup combobox

=cut

sub load_search_history {
    my ($self, $dictionary_id) = @_;

    $self->lookup_field->Clear;
    my $rs = Database->schema->resultset('SearchHistory')->search(
        { 'dictionary_id' => $dictionary_id },
        {
            rows     => $LAST_SEARCH_HISTORY_SIZE,
            group_by => 'text',
            order_by => { -desc => 'search_history_id' },
        }
    );
    while (my $search_history_record = $rs->next) {
        $self->lookup_field->Append($search_history_record->text);
    }
}

=head2 get_selected_phrase

Returns id, phrase and part-of-speech of a selected item

=cut

sub get_selected_phrase {
    my ($self) = @_;

    my $phrase_table_row_id
        = $self->phrase_table->GetNextItem(-1,
        wxLIST_NEXT_ALL, wxLIST_STATE_SELECTED);

    # 0 - ID, 1 - Phrase, 2 - part-of-speech
    return
        map {
            $self->phrase_table->GetItem($phrase_table_row_id, $_)->GetText
        } 0 .. 2;
}

=head2 keybind

TODO add description

=cut

sub keybind {
    my ($self, $event) = @_;

    # It should respond to Ctrl+"R"
    # so if Ctrl key isn't pressed, go away
    return if $event->GetModifiers() != wxMOD_CONTROL;

    given ($event->GetKeyCode()) {
        # Ctrl+"R" and Ctrl+"r"
        when([ord('R'), ord('r')]) {
            $self->lookup();
        }
    }
}

sub FOREIGNBUILDARGS {
    my ($class, @args) = @_;

    # Don't pass the last parameter to the parent object if it's a hashref
    pop @args if ref $args[-1] eq 'HASH';

    return @args;
}

sub BUILDARGS {
    my ($class, $parent) = @_;

    return {
        # parent object
        parent => $parent,
        # if the last parameter is a hashref, consider it as 'options'
        (ref $_[-1] eq 'HASH' ? (options => $_[-1]) : ())
    };
}

sub BUILD {
    my ($self, @args) = @_;

    # layout
    $self->SetSizer($self->vbox);
    $self->vbox->Fit($self);
    $self->Layout();

    # Set focus on search field
    $self->lookup_field->SetFocus();

    for (
        sub {
            my $dict = shift;
            my @li = (Wx::ListItem->new, Wx::ListItem->new);            
            $li[0]->SetText($dict->curr->{language_orig_id}{language_name});
            $li[1]->SetText($dict->curr->{language_tr_id}{language_name});
            $self->phrase_table->SetColumn($LANG_COL[0], $li[0]);
            $self->phrase_table->SetColumn($LANG_COL[1], $li[1]);
        },
        # Load Search History into a lookup combobox
        sub {
            my $dict = shift;
            $self->load_search_history($dict->curr_id);
        },
        sub { $self->lookup() }
        )
    {
        Dict::Learn::Dictionary->cb($_);
    }

    EVT_KEY_UP($self, \&keybind);
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
