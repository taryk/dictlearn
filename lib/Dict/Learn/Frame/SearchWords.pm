package Dict::Learn::Frame::SearchWords 0.1;

use Wx qw[:everything];
use Wx::Event qw[:everything];

use Moose;
use MooseX::NonMoose;
extends 'Wx::Panel';

use Const::Fast;

use Database;
use Dict::Learn::Dictionary;
use Dict::Learn::Frame::Sidebar;
use Dict::Learn::Widget::LookupPhrases;

use common::sense;

use Data::Printer;

=head1 NAME

Dict::Learn::Frame::SearchWords

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

    my $lookup_phrases
        = Dict::Learn::Widget::LookupPhrases->new($self, wxID_ANY,
        wxDefaultPosition, wxDefaultSize);

    return $lookup_phrases;
}

=head2 btn_edit_word

TODO add description

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

=head2 btn_unlink_word

TODO add description

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

=head2 btn_delete_word

TODO add description

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

=head2 vbox_btn_words

TODO add description

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

=head2 hbox_words

TODO add description

=cut

has hbox_words => (
    is         => 'ro',
    isa        => 'Wx::BoxSizer',
    lazy_build => 1,
);

sub _build_hbox_words {
    my $self = shift;

    my $hbox = Wx::BoxSizer->new(wxHORIZONTAL);
    $hbox->Add($self->vbox_btn_words, 0, wxRIGHT | wxEXPAND, 5);
    $hbox->Add($self->lookup_phrases, 2, wxALL | wxEXPAND, 0);

    return $hbox;
}

=head2 st_add_to_test

TODO add description

=cut

has st_add_to_test => (
    is      => 'ro',
    isa     => 'Wx::StaticText',
    default => sub {
        Wx::StaticText->new($_[0], wxID_ANY, 'Add to test', wxDefaultPosition,
            [90,20], wxALIGN_CENTER);
    },
);

=head2 cb_add_to_test

TODO add description

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
                = Database->schema->resultset('TestCategory')
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

=head2 btn_add_to_test

TODO add description

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

=head2 hbox_add_to_test

TODO add description

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


=head2 sidebar

TODO add description

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
    $vbox->Add($self->hbox_words,       2, wxALL | wxGROW | wxEXPAND, 0);
    $vbox->Add($self->hbox_add_to_test, 0, wxALL | wxGROW | wxEXPAND, 0);

    return $vbox;
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
    $hbox->Add($self->vbox,    3, wxALL | wxGROW | wxEXPAND, 0);
    $hbox->Add($self->sidebar, 1, wxGROW | wxEXPAND | wxALL, 0);

    return $hbox;
}

=head1 METHODS

=head2 edit_word

TODO add description

=cut

sub edit_word {
    my $self    = shift;

    my $curr_id = $self->lb_words->GetNextItem(-1, wxLIST_NEXT_ALL,
        wxLIST_STATE_SELECTED);

    my $add_word_page = $self->parent->p_addword;
    my $word_id = $self->get_word_id($curr_id);
    $add_word_page->load_word(word_id => $word_id);
    $self->parent->new_page($add_word_page, "Edit Word #$word_id");
}

=head2 load_phrase

Load a selected phrase into sidebar

=cut

sub load_phrase {
    my ($self, $obj) = @_;

    my $phrase_id = $obj->GetLabel();
    $self->sidebar->load_word(word_id => $phrase_id);
}

=head2 get_word_id

TODO add description

=cut

sub get_word_id {
    my ($self, $rowid) = @_;

    $self->lb_words->GetItem($rowid, 0)->GetText;
}

=head2 delete_word

TODO add description

=cut

sub delete_word {
    my $self    = shift;

    my $curr_id = $self->lb_words->GetNextItem(-1, wxLIST_NEXT_ALL,
        wxLIST_STATE_SELECTED);
    Database->schema->resultset('Word')
        ->delete_one($self->get_word_id($curr_id));
    $self->lookup;
}

=head2 unlink_word

TODO add description

=cut

sub unlink_word {
    my $self    = shift;

    my $curr_id = $self->lb_words->GetNextItem(-1, wxLIST_NEXT_ALL,
        wxLIST_STATE_SELECTED);
    Database->schema->resultset('Word')
        ->unlink_one($self->get_word_id($curr_id));
    $self->lookup;
}

=head2 add_to_test

TODO add description

=cut

sub add_to_test {
    my ($self) = @_;

    my $test_category_id = $self->cb_add_to_test->GetClientData(
        $self->cb_add_to_test->GetSelection());

    my $row_id = $self->lookup_phrases->lb_words->GetNextItem(-1, wxLIST_NEXT_ALL,
        wxLIST_STATE_SELECTED);

    my $word_id = $self->get_word_id($row_id);

    Database->schema->resultset('TestCategoryWords')->create(
        {
            test_category_id => $test_category_id,
            word_id          => $word_id,
            partofspeech_id  => 0,
        }
    );

    my $word = $self->lookup_phrases->lb_words->GetItem($row_id, 1)->GetText;

    $self->set_status_text(
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

    EVT_KEY_UP($self, \&keybind);
    EVT_LIST_ITEM_SELECTED($self, $self->lookup_phrases->lb_words,
        \&load_phrase);
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
