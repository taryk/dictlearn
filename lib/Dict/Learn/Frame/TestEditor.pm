package Dict::Learn::Frame::TestEditor;

use Wx qw[:everything];
use Wx::Event qw[:everything];

use Data::Printer;

use Moose;
use MooseX::NonMoose;
extends 'Wx::Panel';

use Carp qw[ croak confess ];
use Const::Fast;

use common::sense;

use Database;
use Dict::Learn::Dictionary;

const my $TEST_ID => 1;

=head1 NAME

Dict::Learn::Frame::TestEditor

=head1 DESCRIPTION

TODO add description

=head1 ATTRIBUTES

=head2 parent

TODO add description

=cut

has parent => (
    is  => 'ro',
    isa => 'Dict::Learn::Frame',
);

=head2 test_groups

TODO add description

=cut

has test_groups => (
    is         => 'ro',
    isa        => 'Wx::ListCtrl',
    lazy_build => 1,
);

sub _build_test_groups {
    my $self = shift;

    my $test_groups = Wx::ListCtrl->new($self, wxID_ANY, wxDefaultPosition,
        wxDefaultSize, wxLC_REPORT | wxLC_HRULES | wxLC_VRULES);
    $test_groups->InsertColumn(0, '#',     wxLIST_FORMAT_LEFT, 30);
    $test_groups->InsertColumn(1, 'name',  wxLIST_FORMAT_LEFT, 200);
    $test_groups->InsertColumn(2, 'words', wxLIST_FORMAT_LEFT, 30);

    # score: taken (correct/wrong) percentage
    $test_groups->InsertColumn(3, 'score', wxLIST_FORMAT_LEFT, 60);

    EVT_LIST_ITEM_SELECTED($self, $test_groups, \&on_category_select);

    return $test_groups;
}


=head2 btn_add_group

TODO add description

=cut

has btn_add_group => (
    is         => 'ro',
    isa        => 'Wx::Button',
    lazy_build => 1,
);

sub _build_btn_add_group {
    my $self = shift;

    my $btn_add_group = Wx::Button->new($self, wxID_ANY, '+', [20, 20]);
    EVT_BUTTON($self, $btn_add_group, \&add_group);

    return $btn_add_group;
}

=head2 btn_del_group

TODO add description

=cut

has btn_del_group => (
    is         => 'ro',
    isa        => 'Wx::Button',
    lazy_build => 1,
);

sub _build_btn_del_group {
    my $self = shift;

    my $btn_del_group = Wx::Button->new($self, wxID_ANY, '-', [20, 20]);
    EVT_BUTTON($self, $btn_del_group, \&del_group);

    return $btn_del_group;
}

=head2 btn_update_group

TODO add description

=cut

has btn_update_group => (
    is         => 'ro',
    isa        => 'Wx::Button',
    lazy_build => 1,
);

sub _build_btn_update_group {
    my $self = shift;

    my $btn_update_group = Wx::Button->new($self, wxID_ANY, '*', [20, 20]);
    EVT_BUTTON($self, $btn_update_group, \&update_group);

    return $btn_update_group;
}

=head2 hbox_test_groups

TODO add description

=cut

has hbox_test_groups => (
    is         => 'ro',
    isa        => 'Wx::BoxSizer',
    lazy_build => 1,
);

sub _build_hbox_test_groups {
    my $self = shift;

    my $hbox_test_groups = Wx::BoxSizer->new(wxHORIZONTAL);
    $hbox_test_groups->Add($self->btn_add_group,    0, wxRIGHT | wxEXPAND, 5);
    $hbox_test_groups->Add($self->btn_del_group,    0, wxRIGHT | wxEXPAND, 5);
    $hbox_test_groups->Add($self->btn_update_group, 0, wxRIGHT | wxEXPAND, 5);

    return $hbox_test_groups;
}

=head2 vbox_test_groups

TODO add description

=cut

has vbox_test_groups => (
    is         => 'ro',
    isa        => 'Wx::BoxSizer',
    lazy_build => 1,
);

sub _build_vbox_test_groups {
    my $self = shift;

    my $vbox_test_groups = Wx::BoxSizer->new(wxVERTICAL);
    $vbox_test_groups->Add($self->test_groups,      1, wxEXPAND, 0);
    $vbox_test_groups->Add($self->hbox_test_groups, 0, wxTOP,    5);

    return $vbox_test_groups;
}

=head2 test_words

TODO add description

=cut

has test_words => (
    is         => 'ro',
    isa        => 'Wx::ListCtrl',
    lazy_build => 1,
);

sub _build_test_words {
    my $self = shift;

    my $test_words = Wx::ListCtrl->new($self, wxID_ANY, wxDefaultPosition,
        wxDefaultSize, wxLC_REPORT | wxLC_HRULES | wxLC_VRULES);
    $test_words->InsertColumn(0, '#',    wxLIST_FORMAT_LEFT, 50);
    $test_words->InsertColumn(1, 'word', wxLIST_FORMAT_LEFT, 200);

    # score: taken (correct/wrong) percentage
    $test_words->InsertColumn(2, 'score', wxLIST_FORMAT_LEFT, 100);

    return $test_words;
}

=head2 btn_move_left

TODO add description

=cut

has btn_move_left => (
    is      => 'ro',
    isa     => 'Wx::Button',
    lazy    => 1,
    default => sub {
        Wx::Button->new(shift, wxID_ANY, '<- Add', wxDefaultPosition,
            wxDefaultSize)
    },
);

=head2 btn_move_right

TODO add description

=cut

has btn_move_right => (
    is      => 'ro',
    isa     => 'Wx::Button',
    lazy    => 1,
    default => sub {
        Wx::Button->new(shift, wxID_ANY, '-> Remove', wxDefaultPosition,
            wxDefaultSize)
    },
);

=head2 btn_reload

TODO add description

=cut

has btn_reload => (
    is      => 'ro',
    isa     => 'Wx::Button',
    lazy    => 1,
    default => sub {
        Wx::Button->new(shift, wxID_ANY, 'Reload', wxDefaultPosition,
            wxDefaultSize)
    },
);

=head2 vbox_btn

TODO add description

=cut

has vbox_btn => (
    is         => 'ro',
    isa        => 'Wx::BoxSizer',
    lazy_build => 1,
);

sub _build_vbox_btn {
    my $self = shift;

    my $vbox_btn = Wx::BoxSizer->new(wxVERTICAL);
    $vbox_btn->Add($self->btn_move_left,  0, wxLEFT, 5);
    $vbox_btn->Add($self->btn_move_right, 0, wxLEFT, 5);
    $vbox_btn->Add($self->btn_reload,     0, wxLEFT, 5);

    return $vbox_btn;
}

=head2 lookup_phrases

A form for looking up the phrases

=cut

has lookup_phrases => (
    is         => 'ro',
    isa        => 'Dict::Learn::Widget::LookupPhrases',
    lazy_build => 1,
);

sub _build_lookup_phrases {
    my $self = shift;

    my $lookup_phrases = Dict::Learn::Widget::LookupPhrases->new(
        $self, wxID_ANY, wxDefaultPosition, wxDefaultSize,
        {
            translated_only => 1,
            buttons         => 0,
        }
    );

    return $lookup_phrases;
}

=head2 hbox

TODO add description

=cut

has hbox => (
    is         => 'ro',
    isa        => 'Wx::BoxSizer',
    lazy_build => 1,
);

sub _build_hbox {
    my $self = shift;

    my $hbox = Wx::BoxSizer->new(wxHORIZONTAL);
    $hbox->Add($self->vbox_test_groups, 1,          wxEXPAND, 0  );
    $hbox->Add($self->test_words,       1, wxLEFT | wxEXPAND, 5  );
    $hbox->Add($self->vbox_btn,         0, wxTOP,             25 );
    $hbox->Add($self->lookup_phrases,   1, wxLEFT | wxEXPAND, 5  );

    return $hbox;
}

=head2 partofspeech

TODO add description

=cut

has partofspeech => (
    is         => 'ro',
    isa        => 'HashRef',
    lazy_build => 1,
);

sub _build_partofspeech {
    my $self = shift;

    my $partofspeech_rs
        = Database->schema->resultset('PartOfSpeech')
        ->search({}, { select => [qw(partofspeech_id abbr)] });
    my $partofspeech_hashref;
    while (my $partofspeech = $partofspeech_rs->next) {
        $partofspeech_hashref->{ $partofspeech->abbr }
            = $partofspeech->partofspeech_id;
    }
    return $partofspeech_hashref;
}

=head1 METHODS

=cut

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

    # layout
    $self->SetSizer($self->hbox);
    $self->hbox->Fit($self);
    $self->Layout();

    EVT_BUTTON($self, $self->btn_move_left,  \&move_left);
    EVT_BUTTON($self, $self->btn_move_right, \&move_right);
    EVT_BUTTON($self, $self->btn_reload,     \&reload);

    Dict::Learn::Dictionary->cb(
        sub {
            $self->init();
            $self->select_first_item();
        }
    );
}

=head2 init

TODO add description

=cut

sub init {
    my ($self) = @_;

    $self->load_categories();
    $self->lookup_phrases->lookup();
}

=head2 set_status_text

TODO add description

=cut

sub set_status_text {
    my ($self, $status_text) = @_;

    $self->parent->status_bar->SetStatusText($status_text);
}

=head2 load_categories

TODO add description

=cut

sub load_categories {
    my ($self) = @_;

    my $categories
        = Database->schema->resultset('TestCategory')
        ->search(
        {
            dictionary_id => Dict::Learn::Dictionary->curr_id,
        },
        {
            order_by => { -desc => 'test_category_id' },
        }
        );

    $self->test_groups->DeleteAllItems();
    while (my $category = $categories->next()) {
        my $id = $self->test_groups->InsertItem(Wx::ListItem->new);
        $self->test_groups->SetItem($id, 0, $category->test_category_id); # id
        $self->test_groups->SetItem($id, 1, $category->name);             # name
        # $self->test_groups->SetItem($id, 2, $category->name);           # number of words
        # $self->test_groups->SetItem($id, 3, $category->name);           # scrore
    }
}

=head2 on_category_select

TODO add description

=cut

sub on_category_select {
    my ($self, $obj) = @_;

    $self->load_words(category_id => $obj->GetLabel());
}

=head2 load_words

TODO add description

=cut

sub load_words {
    my ($self, %params) = @_;

    $self->test_words->DeleteAllItems();
    my $words
        = Database->schema->resultset('TestCategoryWords')
        ->search(
        {
            test_category_id => $params{category_id},
        },
        {
            join     => 'word_id',
            order_by => { -desc => 'test_category_id' },
        }
        );
    while (my $word = $words->next) {
        my $id = $self->test_words->InsertItem(Wx::ListItem->new);
        $self->test_words->SetItem($id, 0, $word->word_id->word_id); # id
        $self->test_words->SetItem($id, 1, $word->word_id->word);    # name
        # $self->test_words->SetItem($id, 2, $word->word_id->word);  # score
    }
}

=head2 get_selected_category

Returns id and category name of a selected item

=cut

sub get_selected_category {
    my ($self) = @_;

    # selected row id
    my $test_groups_row_id = $self->test_groups->GetNextItem(
        -1, wxLIST_NEXT_ALL, wxLIST_STATE_SELECTED);

    # 0 - ID, 1 - Category Name
    return
        map {
            $self->test_groups->GetItem($test_groups_row_id, $_)->GetText
        } 0 .. 1;
}

=head2 get_selected_test_phrase

Returns id and phrase of a selected item in a test phrases table

=cut

sub get_selected_test_phrase {
    my ($self) = @_;

    # selected row id
    my $test_words_row_id
        = $self->test_words->GetNextItem(-1, wxLIST_NEXT_ALL,
        wxLIST_STATE_SELECTED);

    # 0 - ID, 1 - Phrase
    return
        map {
            $self->test_words->GetItem($test_words_row_id, $_)->GetText
        } 0 .. 1;
}

=head2 move_left

TODO add description

=cut

sub move_left {
    my ($self) = @_;

    my ($category_id, $category_name) = $self->get_selected_category();

    my ($phrase_id, $phrase, $part_of_speech)
        = $self->lookup_phrases->get_selected_phrase();

    my $record_dbix
        = Database->schema->resultset('TestCategoryWords')->find_or_new(
        {
            test_category_id => $category_id,
            word_id          => $phrase_id,
            partofspeech_id  => $self->get_partofspeech_id($part_of_speech),
        },
        );

    if ($record_dbix->in_storage) {
        Wx::MessageBox(
            qq{The word "$phrase" is already in the test "$category_name"},
            q{Can't add},
            wxICON_EXCLAMATION | wxOK | wxCENTRE, $self,
        );
    } else {
        $record_dbix->insert;

        # check current test group
        $self->load_words(category_id => $category_id);
    }
}

=head2 move_right

TODO add description

=cut

sub move_right {
    my ($self) = @_;

    my ($test_phrase_id) = $self->get_selected_test_phrase();

    my ($category_id) = $self->get_selected_category();

    Database->schema->resultset('TestCategoryWords')->search(
        {
            test_category_id => $category_id,
            word_id          => $test_phrase_id,
        },
    )->delete;

    # check current test group
    $self->load_words(category_id => $category_id);
}

=head2 reload

TODO add description

=cut

sub reload {
    my ($self) = @_;

    $self->init();
}

=head2 select_first_item

TODO add description

=cut

sub select_first_item {
    my ($self) = @_;

    $self->test_groups->SetItemState(
        $self->test_groups->GetNextItem(
            -1, wxLIST_NEXT_ALL, wxLIST_STATE_DONTCARE
        ),
        wxLIST_STATE_SELECTED,
        wxLIST_STATE_SELECTED
    );
}

=head2 get_partofspeech_id

TODO add description

=cut

sub get_partofspeech_id {
    my ($self, $part_of_speech) = @_;

    return $self->partofspeech->{$part_of_speech};
}

=head2 add_group

TODO add description

=cut

sub add_group {
    my ($self) = @_;

    my $dialog = Wx::TextEntryDialog->new(
        $self, 'Group name', 'Please enter group name',
        undef, wxOK | wxCANCEL | wxCENTRE,
        wxDefaultPosition
    );

    return if $dialog->ShowModal != wxID_OK;

    my $group_name = $dialog->GetValue;

    Database->schema->resultset('TestCategory')->create(
        {
            test_id          => $TEST_ID,
            dictionary_id    => Dict::Learn::Dictionary->curr_id,
            name             => $group_name,
        },
    );
    $self->load_categories();
}

=head2 del_group

TODO add description

=cut

sub del_group {
    my ($self) = @_;

    my ($category_id) = $self->get_selected_category();

    # `delete_all` method deletes all records from `TestCategoryWords` table
    # related to this category as well
    Database->schema->resultset('TestCategory')->search(
        {
            test_category_id => $category_id,
            test_id          => $TEST_ID,
            dictionary_id    => Dict::Learn::Dictionary->curr_id,
        }
    )->delete_all;

    $self->load_categories();
}

=head2 update_group

TODO add description

=cut

sub update_group {
    my ($self) = @_;

    my ($category_id, $category_name) = $self->get_selected_category();

    my $dialog = Wx::TextEntryDialog->new(
        $self, 'Group name', 'Please enter group name',
        $category_name, wxOK | wxCANCEL | wxCENTRE,
        wxDefaultPosition
    );

    return if $dialog->ShowModal != wxID_OK;

    my $new_category_name = $dialog->GetValue;

    Database->schema->resultset('TestCategory')->search(
        {
            test_category_id => $category_id,
            test_id          => $TEST_ID,
            dictionary_id    => Dict::Learn::Dictionary->curr_id,
        },
    )->update({ name => $new_category_name });

    $self->load_categories();
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
