package Dict::Learn::Frame::TestEditor 0.1;

use Wx qw[:everything];
use Wx::Event qw[:everything];

use Data::Printer;

use Moose;
use MooseX::NonMoose;
extends 'Wx::Panel';

use Carp qw[ croak confess ];

use common::sense;

sub TEST_ID { 1 }

=item parent

=cut

has parent => (
    is  => 'ro',
    isa => 'Dict::Learn::Frame',
);

=item test_groups

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
    $test_groups->InsertColumn(0, '#',     wxLIST_FORMAT_LEFT, 30  );
    $test_groups->InsertColumn(1, 'name',  wxLIST_FORMAT_LEFT, 200 );
    $test_groups->InsertColumn(2, 'words', wxLIST_FORMAT_LEFT, 30  );
    # score: taken (correct/wrong) percentage
    $test_groups->InsertColumn(3, 'score', wxLIST_FORMAT_LEFT, 60  );

    EVT_LIST_ITEM_SELECTED($self, $test_groups, \&on_category_select);
    
    return $test_groups;
}


=item btn_add_group

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

=item btn_del_group

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

=item btn_update_group

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

=item hbox_test_groups

=cut

has hbox_test_groups => (
    is         => 'ro',
    isa        => 'Wx::BoxSizer',
    lazy_build => 1,
);

sub _build_hbox_test_groups {
    my $self = shift;

    my $hbox_test_groups = Wx::BoxSizer->new(wxHORIZONTAL);
    $hbox_test_groups->Add($self->btn_add_group,    0, wxRIGHT | wxGROW, 5);
    $hbox_test_groups->Add($self->btn_del_group,    0, wxRIGHT | wxGROW, 5);
    $hbox_test_groups->Add($self->btn_update_group, 0, wxRIGHT | wxGROW, 5);

    return $hbox_test_groups;
}

=item vbox_test_groups

=cut

has vbox_test_groups => (
    is         => 'ro',
    isa        => 'Wx::BoxSizer',
    lazy_build => 1,
);

sub _build_vbox_test_groups {
    my $self = shift;
    
    my $vbox_test_groups = Wx::BoxSizer->new(wxVERTICAL);
    $vbox_test_groups->Add($self->test_groups, 1, wxEXPAND, 0);
    $vbox_test_groups->Add($self->hbox_test_groups, 0, wxTOP, 5);
    
    return $vbox_test_groups;
}

=item test_words

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
    $test_words->InsertColumn(0, '#',      wxLIST_FORMAT_LEFT, 50  );
    $test_words->InsertColumn(1, 'word',   wxLIST_FORMAT_LEFT, 200 );
    # score: taken (correct/wrong) percentage
    $test_words->InsertColumn(2, 'score', wxLIST_FORMAT_LEFT,  100 );

    return $test_words;
}

=item btn_move_left

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

=item btn_move_right

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

=item btn_reload

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

=item vbox_btn

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

=item word_list

=cut

has word_list => (
    is         => 'ro',
    isa        => 'Wx::ListCtrl',
    lazy_build => 1,
);

sub _build_word_list {
    my $self = shift;

    my $word_list = Wx::ListCtrl->new($self, wxID_ANY, wxDefaultPosition,
        wxDefaultSize, wxLC_REPORT | wxLC_HRULES | wxLC_VRULES);
    $word_list->InsertColumn(0, '#',    wxLIST_FORMAT_LEFT, 50  );
    $word_list->InsertColumn(1, 'word', wxLIST_FORMAT_LEFT, 200 );
    $word_list->InsertColumn(2, 'pos',  wxLIST_FORMAT_LEFT, 30  );
    $word_list->InsertColumn(3, 'tr',   wxLIST_FORMAT_LEFT, 200 );

    return $word_list;
}

=item btn_move_right

=cut

has cb_lookup => (
    is         => 'ro',
    isa        => 'Wx::ComboBox',
    lazy_build => 1,
);

sub _build_cb_lookup {
    my ($self) = @_;

    my $cb_lookup = Wx::ComboBox->new($self, wxID_ANY, '', wxDefaultPosition,
        wxDefaultSize, [], 0, wxDefaultValidator);
    EVT_TEXT_ENTER($self, $cb_lookup, \&lookup);

    return $cb_lookup;
}

=item vbox_word_list

=cut

has vbox_word_list => (
    is         => 'ro',
    isa        => 'Wx::BoxSizer',
    lazy_build => 1,
);

sub _build_vbox_word_list {
    my $self = shift;

    my $vbox_word_list = Wx::BoxSizer->new(wxVERTICAL);
    $vbox_word_list->Add($self->cb_lookup, 0, wxEXPAND, 0 );
    $vbox_word_list->Add($self->word_list, 1, wxEXPAND, 0 );

    return $vbox_word_list;
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
    $hbox->Add($self->vbox_test_groups, 1,          wxEXPAND, 0  );
    $hbox->Add($self->test_words,       1, wxLEFT | wxEXPAND, 5  );
    $hbox->Add($self->vbox_btn,         0, wxTOP,             25 );
    $hbox->Add($self->vbox_word_list,   1, wxLEFT | wxEXPAND, 5  );

    return $hbox;
}

has partofspeech => (
    is         => 'ro',
    isa        => 'HashRef',
    lazy_build => 1,
);

sub _build_partofspeech {
    my $self = shift;

    my $partofspeech_rs
        = $main::ioc->lookup('db')->schema->resultset('PartOfSpeech')
        ->search({}, { select => [qw(partofspeech_id abbr)] });
    my $partofspeech_hashref;
    while (my $partofspeech = $partofspeech_rs->next) {
        $partofspeech_hashref->{ $partofspeech->abbr }
            = $partofspeech->partofspeech_id;
    }
    return $partofspeech_hashref;

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

sub init {
    my ($self) = @_;

    my $categories
        = $main::ioc->lookup('db')->schema->resultset('TestCategory')
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

    $self->lookup();
}

sub lookup {
    my ($self, $event) = @_;

    my %options = ();

    if (my $value = $self->cb_lookup->GetValue) {
        my $word_pattern = "%$value%";

        # TODO Basically, lookup tables in Dict::Learn::Frame::SearchWords and
        # Dict::Learn::Frame::TestEditor are almost the same (except that the
        # later don't have translated words column).
        # Thus, in order to not duplicate code, they can be easily merged into
        # one class.
        if ($value =~ m{^ / (?<filter> \!? \w+ ) $}x) {
            given ($+{filter}) {
                when('irregular') {
                    %options = ( 'word1_id.irregular' => 1 );
                }
                when([qw(words phrases phrasal_verbs idioms)]) {
                    # TODO return only words
                    # it requires to have some kind of tags, which can be
                    # filtered by
                    $self->parent->status_bar->SetStatusText(
                        sprintf
                            'Filter "/%s" is not implemented at the moment ',
                        $+{filter}
                    );
                    return;
                }
                default {
                    $self->parent->status_bar->SetStatusText(
                        sprintf 'Unknown filter: "/%s"', $+{filter});
                    return;
                }
            }
        } else {
            for my $column (
                'word1_id.word',  'word1_id.word2',
                'word1_id.word3', 'word2_id.word'
                )
            {
                push @{ $options{-or} },
                    ($column => { like => $word_pattern });
            }
        }
    }

    my $all_words
        = $main::ioc->lookup('db')->schema->resultset('Words')->search(
        {
            'me.dictionary_id' => Dict::Learn::Dictionary->curr_id,
            %options
        },
        {
            select => [
                'word1_id.word_id', 'word1_id.word', 'partofspeech.abbr',
                { group_concat => 'word2_id.word' },
            ],
            as       => [qw(word_id word partofspeech translations)],
            join     => [qw(word1_id word2_id partofspeech)],
            group_by => [qw(me.word1_id me.partofspeech_id)],
            order_by => { -asc => 'me.word1_id' }
        }
        );

    $self->word_list->DeleteAllItems();
    while (my $word = $all_words->next) {
        my $id = $self->word_list->InsertItem(Wx::ListItem->new);
        $self->word_list->SetItem($id, 0, $word->get_column('word_id'));      # id
        $self->word_list->SetItem($id, 1, $word->get_column('word'));         # word original
        $self->word_list->SetItem($id, 2, $word->get_column('partofspeech')); # word original
        $self->word_list->SetItem($id, 3, $word->get_column('translations')); # word tr
    }
}

sub on_category_select {
    my ($self, $obj) = @_;

    $self->load_words(category_id => $obj->GetLabel());
}

sub load_words {
    my ($self, %params) = @_;

    $self->test_words->DeleteAllItems();
    my $words
        = $main::ioc->lookup('db')->schema->resultset('TestCategoryWords')
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

sub move_left {
    my ($self) = @_;

    # selected row id
    my $word_list_row_id = $self->word_list->GetNextItem(-1, wxLIST_NEXT_ALL,
        wxLIST_STATE_SELECTED);

    my $test_groups_row_id = $self->test_groups->GetNextItem(-1, wxLIST_NEXT_ALL,
        wxLIST_STATE_SELECTED);

    my $category_id
        = $self->test_groups->GetItem($test_groups_row_id, 0)->GetText;
    
    $main::ioc->lookup('db')->schema->resultset('TestCategoryWords')->create(
        {
            test_category_id => $category_id,
            word_id          => $self->get_word_id($word_list_row_id),
            partofspeech_id  => $self->get_partofspeech_id($word_list_row_id),
        },
    );

    # check current test group
    $self->load_words(category_id => $category_id);
}

sub move_right {
    my ($self) = @_;

    # selected row id
    my $test_words_row_id = $self->test_words->GetNextItem(-1, wxLIST_NEXT_ALL,
        wxLIST_STATE_SELECTED);

    my $test_groups_row_id = $self->test_groups->GetNextItem(-1, wxLIST_NEXT_ALL,
        wxLIST_STATE_SELECTED);

    my $category_id = $self->test_groups->GetItem($test_groups_row_id, 0)->GetText;

    $main::ioc->lookup('db')->schema->resultset('TestCategoryWords')->search(
        {
            test_category_id => $category_id,
            word_id          => $self->test_words->GetItem($test_words_row_id, 0)->GetText,
        },
    )->delete;

    # check current test group
    $self->load_words(category_id => $category_id);
}

sub reload {
    my ($self) = @_;

    $self->init();
}

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

sub get_word_id {
    my ($self, $rowid) = @_;

    return $self->word_list->GetItem($rowid, 0)->GetText;
}

sub get_partofspeech_id {
    my ($self, $rowid) = @_;

    return
        $self->partofspeech->{$self->word_list->GetItem($rowid, 2)->GetText};
}

sub add_group {
    my ($self) = @_;

    # TODO add a new test group
}

sub rem_group {
    my ($self) = @_;

    # TODO remove a selected test group
}

sub update_group {
    my ($self) = @_;

    # TODO change name of a selected test group
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 NAME

Dict::Learn::Frame::TestEditor - Perl extension for blah blah blah

=head1 SYNOPSIS

   use Dict::Learn::Frame::TestEditor;
   blah blah blah

=head1 DESCRIPTION

Stub documentation for Dict::Learn::Frame::TestEditor, 

Blah blah blah.

=head2 EXPORT

None by default.

=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

taryk, E<lt>mrtaryk@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by taryk

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut
