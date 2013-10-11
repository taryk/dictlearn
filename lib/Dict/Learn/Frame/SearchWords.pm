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

sub COL_LANG1   {1}
sub COL_LANG2   {3}
sub COL_E_LANG1 {1}
sub COL_E_LANG2 {2}

=item parent

=cut

has parent => (
    is  => 'ro',
    isa => 'Dict::Learn::Frame',
);

=item combobox

=cut

has combobox => (
    is         => 'ro',
    isa        => 'Wx::ComboBox',
    lazy_build => 1,
);

sub _build_combobox {
    my $self     = shift;

    my $combobox = Wx::ComboBox->new($self, wxID_ANY, '', wxDefaultPosition,
        wxDefaultSize, [], 0, wxDefaultValidator);
    EVT_TEXT_ENTER($self, $combobox, \&lookup);

    return $combobox;
}

=item btn_lookup

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

=item lookup_hbox

=cut

has lookup_hbox => (
    is         => 'ro',
    isa        => 'Wx::BoxSizer',
    lazy_build => 1,
);

sub _build_lookup_hbox {
    my $self = shift;

    my $hbox = Wx::BoxSizer->new(wxHORIZONTAL);
    $hbox->Add($self->combobox, 1, wxTOP | wxGROW, 0);
    $hbox->Add($self->btn_lookup, 0);

    return $hbox;
}

=item btn_edit_word

=cut

has btn_edit_word => (
    is         => 'ro',
    isa        => 'Wx::Button',
    lazy_build => 1,
);

sub _build_btn_edit_word {
    my $self = shift;

    my $btn_edit_word
        = Wx::Button->new($self, wxID_ANY, 'Edit', wxDefaultPosition,
        wxDefaultSize);
    EVT_BUTTON($self, $btn_edit_word, \&edit_word);

    return $btn_edit_word;
}

=item btn_unlink_word

=cut

has btn_unlink_word => (
    is         => 'ro',
    isa        => 'Wx::Button',
    lazy_build => 1,
);

sub _build_btn_unlink_word {
    my $self = shift;

    my $btn_unlink_word
        = Wx::Button->new($self, wxID_ANY, 'Unlink', wxDefaultPosition,
        wxDefaultSize);
    EVT_BUTTON($self, $btn_unlink_word, \&unlink_word);

    return $btn_unlink_word;
}

=item btn_delete_word

=cut

has btn_delete_word => (
    is         => 'ro',
    isa        => 'Wx::Button',
    lazy_build => 1,
);

sub _build_btn_delete_word {
    my $self = shift;

    my $btn_delete_word
        = Wx::Button->new($self, wxID_ANY, 'Del', wxDefaultPosition,
        wxDefaultSize);
    EVT_BUTTON($self, $btn_delete_word, \&delete_word);

    return $btn_delete_word;
}

=item vbox_btn_words

=cut

has vbox_btn_words => (
    is         => 'ro',
    isa        => 'Wx::BoxSizer',
    lazy_build => 1,
);

sub _build_vbox_btn_words {
    my $self = shift;

    my $vbox = Wx::BoxSizer->new(wxVERTICAL);
    $vbox->Add($self->btn_edit_word);
    $vbox->Add($self->btn_unlink_word);
    $vbox->Add($self->btn_delete_word);

    return $vbox;
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
        = Wx::ListCtrl->new($self, wxID_ANY, wxDefaultPosition, wxDefaultSize,
        wxLC_REPORT | wxLC_HRULES | wxLC_VRULES);
    $lb_words->InsertColumn(0,         'id',      wxLIST_FORMAT_LEFT, 50);
    $lb_words->InsertColumn(COL_LANG1, 'Eng',     wxLIST_FORMAT_LEFT, 200);
    $lb_words->InsertColumn(2,         'pos',     wxLIST_FORMAT_LEFT, 35);
    $lb_words->InsertColumn(COL_LANG2, 'Ukr',     wxLIST_FORMAT_LEFT, 200);
    $lb_words->InsertColumn(4,         'note',    wxLIST_FORMAT_LEFT, 200);
    $lb_words->InsertColumn(5,         'created', wxLIST_FORMAT_LEFT, 150);
    EVT_LIST_ITEM_SELECTED($self, $lb_words, \&load_examples);

    Dict::Learn::Dictionary->cb(
        sub {
            my $dict = shift;
            my @li = (Wx::ListItem->new, Wx::ListItem->new);
            $li[0]->SetText($dict->curr->{language_orig_id}{language_name});
            $li[1]->SetText($dict->curr->{language_tr_id}{language_name});
            $self->lb_words->SetColumn(COL_LANG1, $li[0]);
            $self->lb_words->SetColumn(COL_LANG2, $li[1]);
        }
    );
    
    return $lb_words;
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

    my $hbox = Wx::BoxSizer->new(wxHORIZONTAL);
    $hbox->Add($self->vbox_btn_words, 0, wxRIGHT, 5);
    $hbox->Add($self->lb_words, 2, wxALL | wxGROW | wxEXPAND, 0);

    return $hbox;
}

=item btn_add_example

=cut

has btn_add_example => (
    is         => 'ro',
    isa        => 'Wx::Button',
    lazy_build => 1,
);

sub _build_btn_add_example {
    my $self = shift;

    my $btn_add_example
        = Wx::Button->new($self, wxID_ANY, 'Add', wxDefaultPosition,
        wxDefaultSize);
    EVT_BUTTON($self, $btn_add_example, \&add_example);

    return $btn_add_example;
}

=item btn_edit_example

=cut

has btn_edit_example => (
    is         => 'ro',
    isa        => 'Wx::Button',
    lazy_build => 1,
);

sub _build_btn_edit_example {
    my $self = shift;

    my $btn_edit_example
        = Wx::Button->new($self, wxID_ANY, 'Edit', wxDefaultPosition,
        wxDefaultSize);
    EVT_BUTTON($self, $btn_edit_example, \&edit_example);

    return $btn_edit_example;
}

=item btn_unlink_example

=cut

has btn_unlink_example => (
    is         => 'ro',
    isa        => 'Wx::Button',
    lazy_build => 1,
);

sub _build_btn_unlink_example {
    my $self = shift;

    my $btn_unlink_example
        = Wx::Button->new($self, wxID_ANY, 'Unlink', wxDefaultPosition,
        wxDefaultSize);
    EVT_BUTTON($self, $btn_unlink_example, \&unlink_example);

    return $btn_unlink_example;
}

=item btn_delete_example

=cut

has btn_delete_example => (
    is         => 'ro',
    isa        => 'Wx::Button',
    lazy_build => 1,
);

sub _build_btn_delete_example {
    my $self = shift;

    my $btn_delete_example
        = Wx::Button->new($self, wxID_ANY, 'Del', wxDefaultPosition,
        wxDefaultSize);
    EVT_BUTTON($self, $btn_delete_example, \&delete_example);

    return $btn_delete_example;
}

=item vbox_btn_examples

=cut

has vbox_btn_examples => (
    is         => 'ro',
    isa        => 'Wx::BoxSizer',
    lazy_build => 1,
);

sub _build_vbox_btn_examples {
    my $self = shift;

    my $vbox = Wx::BoxSizer->new(wxVERTICAL);
    $vbox->Add($self->btn_add_example);
    $vbox->Add($self->btn_edit_example);
    $vbox->Add($self->btn_unlink_example);
    $vbox->Add($self->btn_delete_example);

    return $vbox;
}

=item lb_examples

=cut

has lb_examples => (
    is         => 'ro',
    isa        => 'Wx::ListCtrl',
    lazy_build => 1,
);

sub _build_lb_examples {
    my $self = shift;

    my $lb_examples
        = Wx::ListCtrl->new($self, wxID_ANY, wxDefaultPosition, wxDefaultSize,
        wxLC_REPORT | wxLC_HRULES | wxLC_VRULES);
    $lb_examples->InsertColumn(0,           'id',   wxLIST_FORMAT_LEFT, 50);
    $lb_examples->InsertColumn(COL_E_LANG1, 'Eng',  wxLIST_FORMAT_LEFT, 200);
    $lb_examples->InsertColumn(COL_E_LANG2, 'Ukr',  wxLIST_FORMAT_LEFT, 200);
    $lb_examples->InsertColumn(3,           'Note', wxLIST_FORMAT_LEFT, 150);

    Dict::Learn::Dictionary->cb(
        sub {
            my $dict = shift;
            my @li = (Wx::ListItem->new, Wx::ListItem->new);
            $li[0]->SetText($dict->curr->{language_orig_id}{language_name});
            $li[1]->SetText($dict->curr->{language_tr_id}{language_name});
            $self->lb_examples->SetColumn(COL_E_LANG1, $li[0]);
            $self->lb_examples->SetColumn(COL_E_LANG2, $li[1]);
        }
    );
    
    return $lb_examples;
}

=item hbox_examples

=cut

has hbox_examples => (
    is         => 'ro',
    isa        => 'Wx::BoxSizer',
    lazy_build => 1,
);

sub _build_hbox_examples {
    my $self = shift;

    my $hbox = Wx::BoxSizer->new(wxHORIZONTAL);
    $hbox->Add($self->vbox_btn_examples, 0, wxRIGHT, 5);
    $hbox->Add($self->lb_examples, 2, wxALL | wxGROW | wxEXPAND, 0);

    return $hbox;
}

=item st_add_to_test

=cut

has st_add_to_test => (
    is      => 'ro',
    isa     => 'Wx::StaticText',
    default => sub {
        Wx::StaticText->new($_[0], wxID_ANY, 'Add to test', wxDefaultPosition,
            [90,20], wxALIGN_CENTER);
    },
);

=item cb_add_to_test

=cut

has cb_add_to_test => (
    is      => 'ro',
    isa     => 'Wx::ComboBox',
    lazy_build => 1,
);

sub _build_cb_add_to_test {
    my $self = shift;  
    
    my $cb
        = Wx::ComboBox->new($self, wxID_ANY, '', wxDefaultPosition,
        wxDefaultSize, [],
        wxCB_DROPDOWN|wxCB_READONLY, wxDefaultValidator);

    Dict::Learn::Dictionary->cb(
        sub {
            my $dict = shift;
            my $test_categories_rs
                = $main::ioc->lookup('db')->schema->resultset('TestCategory')
                ->search({dictionary_id => $dict->curr_id});
            $cb->Clear();
            for ($test_categories_rs->all()) {
                $cb->Append($_->name, $_->test_category_id);
            }
            $cb->SetSelection(0);
        }
    );
    
    return $cb;
}

=item btn_add_to_test

=cut

has btn_add_to_test => (
    is         => 'ro',
    isa        => 'Wx::Button',
    lazy_build => 1,
);

sub _build_btn_add_to_test {
    my $self = shift;

    my $btn_add_to_test = Wx::Button->new($self, wxID_ANY, 'Add', [20, 20]);
    EVT_BUTTON($self, $btn_add_to_test, \&add_to_test);

    return $btn_add_to_test;
}

=item hbox_add_to_test

=cut

has hbox_add_to_test => (
    is         => 'ro',
    isa        => 'Wx::BoxSizer',
    lazy_build => 1,
);

sub _build_hbox_add_to_test {
    my $self = shift;

    my $hbox = Wx::BoxSizer->new(wxHORIZONTAL);
    $hbox->Add($self->st_add_to_test,  0, wxTOP | wxBOTTOM, 5);
    $hbox->Add($self->cb_add_to_test,  0, wxTOP | wxBOTTOM, 5);
    $hbox->Add($self->btn_add_to_test, 0, wxTOP | wxBOTTOM, 5);

    return $hbox;
}


=item sidebar

=cut

has sidebar => (
    is      => 'ro',
    isa     => 'Dict::Learn::Frame::Sidebar',
    lazy    => 1,
    default => sub {
        Dict::Learn::Frame::Sidebar->new($_[0], wxID_ANY, wxDefaultPosition,
            wxDefaultSize);
    },
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
    $vbox->Add($self->lookup_hbox,      0, wxTOP | wxGROW,            5);
    $vbox->Add($self->hbox_words,       2, wxALL | wxGROW | wxEXPAND, 0);
    $vbox->Add($self->hbox_add_to_test, 0, wxALL | wxGROW | wxEXPAND, 0);
    $vbox->Add($self->hbox_examples,    1, wxALL | wxGROW | wxEXPAND, 0);

    return $vbox;
}

=item hbox

=cut

has hbox => (
    is         => 'ro',
    isa        => 'Wx::BoxSizer',
    lazy_build => 1,
);

sub _build_hbox {
    my $self = shift;

    my $hbox = Wx::BoxSizer->new(wxHORIZONTAL);
    $hbox->Add($self->vbox,    3, wxALL | wxGROW | wxEXPAND, 0);
    $hbox->Add($self->sidebar, 1, wxGROW | wxEXPAND | wxALL, 0);

    return $hbox;
}

sub lookup {
    my ($self, $event) = @_;

    my $value = $self->combobox->GetValue;
    my $lang_id
        = Dict::Learn::Dictionary->curr->{language_orig_id}{language_id};

    my @result;
    if ($value =~ m{^ / (?<command> \w+ ) $}x) {
        given ($+{command}) {
            when('untranslated') {
                my $rs
                    = $main::ioc->lookup('db')->schema->resultset('Word')
                    ->search(
                    {
                        'me.lang_id'         => $lang_id,
                        'rel_words.word2_id' => undef,
                    },
                    {
                        join   => ['rel_words'],
                        select => [
                            'me.word_id',   'me.word',
                            'me.word2',     'me.word3',
                            'me.irregular', 'me.mdate',
                            'me.cdate',     'me.note',
                            'me.in_test',
                        ],
                        as => [
                            qw[
                                word_id word_orig word2 word3
                                is_irregular mdate cdate
                                note in_test
                                ]
                        ],
                        order_by => { -asc => 'me.cdate' },
                    }
                    );
                $rs->result_class(
                    'DBIx::Class::ResultClass::HashRefInflator');
                @result = $rs->all();
            }
            default {
            }
        }
    } else {
        @result
            = $main::ioc->lookup('db')->schema->resultset('Word')
            ->find_ones_cached(
                word    => $value,
                lang_id => $lang_id,
            );
    }

    $self->lb_words->DeleteAllItems();
    for my $item (@result) {
        my $id = $self->lb_words->InsertItem(Wx::ListItem->new);
        my $word
            = $item->{is_irregular}
            ? join(' / ' => $item->{word_orig}, $item->{word2}, $item->{word3})
            : $item->{word_orig};
        $self->lb_words->SetItem($id, 0,         $item->{word_id});
        $self->lb_words->SetItem($id, COL_LANG1, $word);
        $self->lb_words->SetItem($id, 2,         $item->{partofspeech} // '');
        $self->lb_words->SetItem($id, COL_LANG2, $item->{word_tr} // '');
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
        word_id => $self->get_word_id($curr_id));

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
    my ($self, $obj) = @_;

    my $word_id = $obj->GetLabel();
    $self->lb_examples->DeleteAllItems();
    my @items
        = $main::ioc->lookup('db')->schema->resultset('Example')->select(
            word_id       => $word_id,
            dictionary_id => Dict::Learn::Dictionary->curr_id,
        );
    for my $item (@items) {
        my $id = $self->lb_examples->InsertItem(Wx::ListItem->new);
        $self->lb_examples->SetItem($id, 0,           $item->{example_id});
        $self->lb_examples->SetItem($id, COL_E_LANG1, $item->{example_orig});
        $self->lb_examples->SetItem($id, COL_E_LANG2, $item->{example_tr});
        $self->lb_examples->SetItem($id, 3,           $item->{note});
    }

    $self->sidebar->load_word(word_id => $word_id);
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

sub add_to_test {
    my ($self) = @_;

    my $test_category_id = $self->cb_add_to_test->GetClientData(
        $self->cb_add_to_test->GetSelection());

    my $row_id = $self->lb_words->GetNextItem(-1, wxLIST_NEXT_ALL,
        wxLIST_STATE_SELECTED);
    
    my $word_id = $self->get_word_id($row_id);

    $main::ioc->lookup('db')->schema->resultset('TestCategoryWords')->create(
        {
            test_category_id => $test_category_id,
            word_id          => $word_id,
            partofspeech_id  => 0,
        }
    );

    my $word = $self->lb_words->GetItem($row_id, 1)->GetText;

    $self->parent->status_bar->SetStatusText(
        sprintf 'Word "%s" has been added to "%s" test',
        $word, $self->cb_add_to_test->GetValue()
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

    
    Dict::Learn::Dictionary->cb(sub { $self->lookup() });
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
