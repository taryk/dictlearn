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

    EVT_LIST_ITEM_SELECTED($self, $test_groups, \&load_words);
    
    return $test_groups;
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
    $hbox->Add($self->test_groups, 1,          wxEXPAND, 0  );
    $hbox->Add($self->test_words,  1, wxLEFT | wxEXPAND, 5  );
    $hbox->Add($self->vbox_btn,    0, wxTOP,             25 );
    $hbox->Add($self->word_list,   1, wxLEFT | wxEXPAND, 5  );

    return $hbox;
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

    Dict::Learn::Dictionary->cb(sub { $self->init() });
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

    my $all_words
        = $main::ioc->lookup('db')->schema->resultset('Words')->search(
        {
            'me.dictionary_id' => Dict::Learn::Dictionary->curr_id,
        },
        {
            select => [
                'word1_id.word_id', 'word1_id.word', 'wordclass.abbr',
                { group_concat => 'word2_id.word' },
            ],
            as       => [qw(word_id word partofspeach translations)],
            join     => [qw(word1_id word2_id wordclass)],
            group_by => [qw(me.word1_id me.wordclass_id)],
            order_by => { -asc => 'me.word1_id' }
        }
        );

    $self->word_list->DeleteAllItems();
    while (my $word = $all_words->next) {
        my $id = $self->word_list->InsertItem(Wx::ListItem->new);
        $self->word_list->SetItem($id, 0, $word->get_column('word_id'));      # id
        $self->word_list->SetItem($id, 1, $word->get_column('word'));         # word original
        $self->word_list->SetItem($id, 2, $word->get_column('partofspeach')); # word original
        $self->word_list->SetItem($id, 3, $word->get_column('translations')); # word tr
    }

    $self->select_first_item();
}

sub load_words {
    my ($self, $obj) = @_;

    $self->test_words->DeleteAllItems();
    my $category_id = $obj->GetLabel();
    my $words
        = $main::ioc->lookup('db')->schema->resultset('TestCategoryWords')
        ->search(
        {
            test_category_id => $category_id,
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
}

sub move_right {
    my ($self) = @_;
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
