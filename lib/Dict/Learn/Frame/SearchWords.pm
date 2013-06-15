package Dict::Learn::Frame::SearchWords 0.1;

use Wx qw[:everything];
use Wx::Event qw[:everything];

use Moose;
use MooseX::NonMoose;
extends 'Wx::Panel';

use Dict::Learn::Dictionary;
use Dict::Learn::Frame::Sidebar;

use common::sense;

use Data::Printer;

sub COL_LANG1   { 1 }
sub COL_LANG2   { 3 }
sub COL_E_LANG1 { 1 }
sub COL_E_LANG2 { 2 }

has parent => (
    is  => 'ro',
    isa => 'Dict::Learn::Frame',
);

has combobox => (
    is => 'ro',
    isa => 'Wx::ComboBox',
    lazy    => 1,
    default => sub {
        Wx::ComboBox->new(
            $_[0], wxID_ANY, '', wxDefaultPosition, wxDefaultSize, [], 0,
            wxDefaultValidator
        )
    }
);

has btn_lookup => (
    is => 'ro',
    isa => 'Wx::Button',
    lazy    => 1,
    default => sub { Wx::Button->new($_[0], wxID_ANY, '#', [20, 20]) },
);

has lookup_hbox => (
    is => 'ro',
    isa => 'Wx::BoxSizer',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $hbox = Wx::BoxSizer->new(wxHORIZONTAL);
        $hbox->Add($self->combobox, 1, wxTOP | wxGROW, 0);
        $hbox->Add($self->btn_lookup, 0);
        return $hbox;
    },
);

has btn_edit_word => (
    is      => 'ro',
    isa     => 'Wx::Button',
    lazy    => 1,
    default => sub {
        Wx::Button->new($_[0], wxID_ANY, 'Edit', wxDefaultPosition,
            wxDefaultSize);
    },
);

has btn_unlink_word => (
    is => 'ro',
    isa => 'Wx::Button',
    lazy    => 1,
    default => sub {
        Wx::Button->new(
            $_[0], wxID_ANY, 'Unlink', wxDefaultPosition, wxDefaultSize
        )
    },
);

has btn_delete_word => (
    is => 'ro',
    isa => 'Wx::Button',
    lazy    => 1,
    default => sub {
        Wx::Button->new(
            $_[0], wxID_ANY, 'Del', wxDefaultPosition, wxDefaultSize
        )
    }
);

has vbox_btn_words => (
    is => 'ro',
    isa => 'Wx::BoxSizer',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $vbox = Wx::BoxSizer->new(wxVERTICAL);
        $vbox->Add($self->btn_edit_word);
        $vbox->Add($self->btn_unlink_word);
        $vbox->Add($self->btn_delete_word);
        return $vbox;
    },
);

has lb_words => (
    is => 'ro',
    isa => 'Wx::ListCtrl',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $lb_words = Wx::ListCtrl->new(
            $self,             wxID_ANY,
            wxDefaultPosition, wxDefaultSize,
            wxLC_REPORT | wxLC_HRULES | wxLC_VRULES
        );
        $lb_words->InsertColumn(0,         'id',   wxLIST_FORMAT_LEFT, 50);
        $lb_words->InsertColumn(COL_LANG1, 'Eng',  wxLIST_FORMAT_LEFT, 200);
        $lb_words->InsertColumn(2,         'wc',   wxLIST_FORMAT_LEFT, 35);
        $lb_words->InsertColumn(COL_LANG2, 'Ukr',  wxLIST_FORMAT_LEFT, 200);
        $lb_words->InsertColumn(4,         'note', wxLIST_FORMAT_LEFT, 200);
        $lb_words->InsertColumn(5, 'created', wxLIST_FORMAT_LEFT, 150);
        return $lb_words;
    },
);

has hbox_words => (
    is => 'ro',
    isa => 'Wx::BoxSizer',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $hbox = Wx::BoxSizer->new(wxHORIZONTAL);
        $hbox->Add($self->vbox_btn_words, 0, wxRIGHT, 5);
        $hbox->Add($self->lb_words, 2, wxALL | wxGROW | wxEXPAND, 0);
        return $hbox;
    },
);

has btn_add_example => (
    is => 'ro',
    isa => 'Wx::Button',
    lazy    => 1,
    default => sub {
        Wx::Button->new(
            $_[0], wxID_ANY, 'Add', wxDefaultPosition, wxDefaultSize
        )
    },
);

has btn_edit_example => (
    is => 'ro',
    isa => 'Wx::Button',
    lazy    => 1,
    default => sub {
        Wx::Button->new(
            $_[0], wxID_ANY, 'Edit', wxDefaultPosition, wxDefaultSize
        )
    },
);

has btn_unlink_example => (
    is => 'ro',
    isa => 'Wx::Button',
    lazy    => 1,
    default => sub {
        Wx::Button->new(
            $_[0], wxID_ANY, 'Unlink', wxDefaultPosition, wxDefaultSize
        )
    },
);

has btn_delete_example => (
    is => 'ro',
    isa => 'Wx::Button',
    lazy    => 1,
    default => sub {
        Wx::Button->new(
            $_[0], wxID_ANY, 'Del', wxDefaultPosition, wxDefaultSize
        )
    },
);

has vbox_btn_examples => (
    is => 'ro',
    isa => 'Wx::BoxSizer',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $vbox = Wx::BoxSizer->new(wxVERTICAL);
        $vbox->Add($self->btn_add_example);
        $vbox->Add($self->btn_edit_example);
        $vbox->Add($self->btn_unlink_example);
        $vbox->Add($self->btn_delete_example);
        return $vbox;
    },
);

has lb_examples => (
    is => 'ro',
    isa => 'Wx::ListCtrl',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $lb_examples = Wx::ListCtrl->new(
            $self,             wxID_ANY,
            wxDefaultPosition, wxDefaultSize,
            wxLC_REPORT | wxLC_HRULES | wxLC_VRULES
        );
        $lb_examples->InsertColumn(0, 'id', wxLIST_FORMAT_LEFT, 50);
        $lb_examples->InsertColumn(COL_E_LANG1, 'Eng', wxLIST_FORMAT_LEFT,
            200);
        $lb_examples->InsertColumn(COL_E_LANG2, 'Ukr', wxLIST_FORMAT_LEFT,
            200);
        $lb_examples->InsertColumn(3, 'Note', wxLIST_FORMAT_LEFT, 150);
        return $lb_examples;
    },
);

has hbox_examples => (
    is => 'ro',
    isa => 'Wx::BoxSizer',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $hbox = Wx::BoxSizer->new(wxHORIZONTAL);
        $hbox->Add($self->vbox_btn_examples, 0, wxRIGHT, 5);
        $hbox->Add($self->lb_examples, 2,
            wxALL | wxGROW | wxEXPAND, 0);
        return $hbox;
    },
);

has sidebar => (
    is => 'ro',
    isa => 'Dict::Learn::Frame::Sidebar',
    lazy    => 1,
    default => sub {
        Dict::Learn::Frame::Sidebar->new(
            $_[0], wxID_ANY, wxDefaultPosition, wxDefaultSize
        )
    },
);

has vbox => (
    is      => 'ro',
    isa     => 'Wx::BoxSizer',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $vbox = Wx::BoxSizer->new(wxVERTICAL);
        $vbox->Add($self->lookup_hbox,   0, wxTOP | wxGROW,            5);
        $vbox->Add($self->hbox_words,    2, wxALL | wxGROW | wxEXPAND, 0);
        $vbox->Add($self->hbox_examples, 1, wxALL | wxGROW | wxEXPAND, 0);
        return $vbox;
    },
);

has hbox => (
    is      => 'ro',
    isa     => 'Wx::BoxSizer',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $hbox = Wx::BoxSizer->new(wxHORIZONTAL);
        $hbox->Add($self->vbox,    3, wxALL | wxGROW | wxEXPAND, 0);
        $hbox->Add($self->sidebar, 1, wxGROW | wxEXPAND | wxALL, 0);
        return $hbox;
    },
);

sub lookup {
    my ($self, $event) = @_;
    $self->lb_words->DeleteAllItems();
    for my $item (
        $main::ioc->lookup('db')->schema->resultset('Word')->find_ones_cached(
            word => $self->combobox->GetValue,
            lang_id =>
                Dict::Learn::Dictionary->curr->{language_orig_id}{language_id}
        )
        )
    {
        my $id = $self->lb_words->InsertItem(Wx::ListItem->new);
        my $word
            = $item->{is_irregular}
            ? join(' / ' => $item->{word_orig}, $item->{word2},
            $item->{word3})
            : $item->{word_orig};
        $self->lb_words->SetItem($id, 0,         $item->{word_id});
        $self->lb_words->SetItem($id, COL_LANG1, $word);
        $self->lb_words->SetItem($id, 2,         $item->{wordclass});
        $self->lb_words->SetItem($id, COL_LANG2, $item->{word_tr});
        $self->lb_words->SetItem($id, 4,         $item->{note});
        $self->lb_words->SetItem($id, 5,         $item->{cdate});
    }
    $self->select_first_item;
}

sub edit_word {
    my $self    = shift;
    my $curr_id = $self->lb_words->GetNextItem(-1, wxLIST_NEXT_ALL,
        wxLIST_STATE_SELECTED);

    $self->parent->p_addword->load_word(
        word_id => $self->get_word_id($curr_id),);

    $self->parent->notebook->ChangeSelection(1);
}

sub edit_example {
    my $self    = shift;
    my $curr_id = $self->lb_examples->GetNextItem(-1, wxLIST_NEXT_ALL,
        wxLIST_STATE_SELECTED);

    $self->parent->p_addexample->load_example(
        example_id => $self->get_example_id($curr_id),);

    $self->parent->notebook->ChangeSelection(2);
}

sub load_examples {
    my $self = shift;
    my $obj  = shift;
    my $id   = $obj->GetLabel();
    $self->lb_examples->DeleteAllItems();
    my @items
        = $main::ioc->lookup('db')->schema->resultset('Example')->select(
        word_id       => $id,
        dictionary_id => Dict::Learn::Dictionary->curr_id,
        );
    for my $item (@items) {
        my $id = $self->lb_examples->InsertItem(Wx::ListItem->new);
        $self->lb_examples->SetItem($id, 0,           $item->{example_id});
        $self->lb_examples->SetItem($id, COL_E_LANG1, $item->{example_orig});
        $self->lb_examples->SetItem($id, COL_E_LANG2, $item->{example_tr});
        $self->lb_examples->SetItem($id, 3,           $item->{note});
    }

    $self->sidebar->load_word(word_id => $id);
}

sub get_word_id {
    my ($self, $rowid) = @_;
    $self->lb_words->GetItem($rowid, 0)->GetText;
}

sub get_example_id {
    my ($self, $rowid) = @_;
    $self->lb_examples->GetItem($rowid, 0)->GetText;
}

sub delete_word {
    my $self    = shift;
    my $curr_id = $self->lb_words->GetNextItem(-1, wxLIST_NEXT_ALL,
        wxLIST_STATE_SELECTED);
    $main::ioc->lookup('db')->schema->resultset('Word')
        ->delete_one($self->get_word_id($curr_id));
    $self->lookup;
}

sub unlink_word {
    my $self    = shift;
    my $curr_id = $self->lb_words->GetNextItem(-1, wxLIST_NEXT_ALL,
        wxLIST_STATE_SELECTED);
    $main::ioc->lookup('db')->schema->resultset('Word')
        ->unlink_one($self->get_word_id($curr_id));
    $self->lookup;
}

sub delete_example {
    my $self    = shift;
    my $curr_id = $self->lb_examples->GetNextItem(-1, wxLIST_NEXT_ALL,
        wxLIST_STATE_SELECTED);
    $main::ioc->lookup('db')->schema->resultset('Example')
        ->delete_one($self->get_example_id($curr_id));
    $self->lookup;
}

sub unlink_example {
    my $self    = shift;
    my $curr_id = $self->lb_examples->GetNextItem(-1, wxLIST_NEXT_ALL,
        wxLIST_STATE_SELECTED);
    $main::ioc->lookup('db')->schema->resultset('Example')
        ->unlink_one($self->get_example_id($curr_id));
    $self->lookup;
}

sub select_first_item {
    my $self = shift;
    $self->lb_words->SetItemState(
        $self->lb_words->GetNextItem(
            -1, wxLIST_NEXT_ALL, wxLIST_STATE_DONTCARE
        ),
        wxLIST_STATE_SELECTED,
        wxLIST_STATE_SELECTED
    );
}

sub FOREIGNBUILDARGS {
    my ($class, $parent, @args) = @_;
    return @args;
}

sub BUILDARGS {
    my ($class, $parent) = @_;
    return {parent => $parent};
}

sub BUILD {
    my ($self, @args) = @_;

    # layout
    $self->SetSizer($self->hbox);
    $self->hbox->Fit($self);
    $self->Layout();

    # events
    # TODO do searching on fly
    EVT_TEXT_ENTER($self, $self->combobox, \&lookup);
    EVT_BUTTON($self, $self->btn_lookup,         \&lookup);
    EVT_BUTTON($self, $self->btn_edit_word,      \&edit_word);
    EVT_BUTTON($self, $self->btn_unlink_word,    \&unlink_word);
    EVT_BUTTON($self, $self->btn_delete_word,    \&delete_word);
    EVT_BUTTON($self, $self->btn_add_example,    \&add_example);
    EVT_BUTTON($self, $self->btn_edit_example,   \&edit_example);
    EVT_BUTTON($self, $self->btn_unlink_example, \&unlink_example);
    EVT_BUTTON($self, $self->btn_delete_example, \&delete_example);
    EVT_LIST_ITEM_SELECTED($self, $self->lb_words, \&load_examples);

    Dict::Learn::Dictionary->cb(
        sub {
            my $dict = shift;
            my @li = (Wx::ListItem->new, Wx::ListItem->new);
            $li[0]->SetText($dict->curr->{language_orig_id}{language_name});
            $li[1]->SetText($dict->curr->{language_tr_id}{language_name});
            $self->lb_words->SetColumn(COL_LANG1, $li[0]);
            $self->lb_words->SetColumn(COL_LANG2, $li[1]);
            $self->lb_examples->SetColumn(COL_E_LANG1, $li[0]);
            $self->lb_examples->SetColumn(COL_E_LANG2, $li[1]);
            $self->lookup;
        }
    );

}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
