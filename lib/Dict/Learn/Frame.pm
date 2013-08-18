package Dict::Learn::Frame 0.1;

use Wx qw[:everything];
use Wx::Grid;
use Wx::Event qw[:everything];

use Moose;
use MooseX::NonMoose;
extends 'Wx::Frame';

use Carp qw[ croak confess ];
use Data::Printer;
use File::Basename 'dirname';

use common::sense;

use Dict::Learn::Db;
use Dict::Learn::Dictionary;
use Dict::Learn::Export;
use Dict::Learn::Frame::AddWord;
use Dict::Learn::Frame::GridWords;
use Dict::Learn::Frame::IrregularVerbsTest;
use Dict::Learn::Frame::SearchWords;
use Dict::Learn::Frame::TestEditor;
use Dict::Learn::Frame::TestSummary;
use Dict::Learn::Frame::TranslationTest;
use Dict::Learn::Import;

=item DICT_OFFSET

A hardcoded offset to distinguish dictionaries IDs from other IDs

=cut

sub DICT_OFFSET { 100 }

=item _MENU_ID

 In: $menu_id
 Out: $menu_id_including_offset

=cut

sub _MENU_ID { int(shift) + DICT_OFFSET }

=item _DICT_ID

 In: $dict_id
 Out: $dict_id_including_offset

=cut

sub _DICT_ID { int(shift) - DICT_OFFSET }

=item next_menu_id

Get id for next menu element

=cut

{
    my $menu_id = 0;

    sub next_menu_id {
        $menu_id++
    }
}

=item parent

=cut

has parent => ( is => 'ro' );

=item vbox

=cut

has vbox => (
    is      => 'ro',
    isa     => 'Wx::BoxSizer',
    lazy    => 1,
    default => sub { Wx::BoxSizer->new(wxVERTICAL) },
);

=item menu_bar

=cut

has menu_bar => (
    is         => 'ro',
    isa        => 'Wx::MenuBar',
    lazy_build => 1,
);

sub _build_menu_bar {
    my ($self) = @_;

    my $menubar = Wx::MenuBar->new(0);

    my @menu = (
        [ Dictionaries => $self->menu_dicts ],
        [ DB => $self->menu_db ],
        [ Translate => $self->menu_trans ],
    );

    for my $menu_item (@menu) {
        my ($caption, $menu_ref) = @$menu_item;
        $menubar->Append($menu_ref, $caption);
    }

    $menubar
}

=item menu_dicts

=cut

has menu_dicts => (
    is         => 'ro',
    isa        => 'Wx::Menu',
    lazy_build => 1,
);

sub _build_menu_dicts {
    my ($self) = @_;

    my $menu_dicts = Wx::Menu->new;

    # Wx::MenuItem->new( $menu_dicts, wxID_ANY, "Test", "", wxITEM_NORMAL)
    for (sort { $a->{dictionary_id} <=> $b->{dictionary_id} }
        values %{ Dict::Learn::Dictionary->all })
    {
        $menu_dicts->AppendRadioItem(_MENU_ID($_->{dictionary_id}),
            $_->{dictionary_name});

        # event
        EVT_MENU($self, _MENU_ID($_->{dictionary_id}), \&dictionary_check);
    }

    $menu_dicts
}

=item menu_db

=cut

has menu_db => (
    is         => 'ro',
    isa        => 'Wx::Menu',
    lazy_build => 1,
);

sub _build_menu_db {
    my ($self) = @_;
    my $menu_db = Wx::Menu->new;

    my @menu = (
        [ 'Export'             => \&db_export ],
        [ 'Import'             => \&db_import ],
        [ 'Clear All Data'     => \&db_clear ],
        [ 'Clear Test Results' => \&db_clear_test_results ],
        [ 'Analyze'            => \&analyze ],
        [ 'Reset Analyzer'     => \&reset_analyzer ],
    );

    for my $menu_item (@menu) {
        my ($caption, $coderef) = @$menu_item;
        my $menu_id = $self->next_menu_id;
        $menu_db->Append($menu_id, $caption);
        EVT_MENU($self, $menu_id, $coderef);
    }

    $menu_db
}

=item menu_trans

=cut

has menu_trans => (
    is         => 'ro',
    isa        => 'Wx::Menu',
    lazy_build => 1,
);

sub _build_menu_trans {
    my ($self) = @_;
    my $menu_trans = Wx::Menu->new;

    for my $tran_backend (@{$self->tran->get_backends_list}) {
        my $menu_id = $self->next_menu_id;
        $menu_trans->AppendRadioItem($menu_id, $tran_backend);
        EVT_MENU($self, $menu_id, \&set_tran_backend);
    }

    $menu_trans
}

=item status_bar

=cut

has status_bar => (
    is      => 'ro',
    lazy    => 1,
    default => sub { shift->CreateStatusBar(1, wxST_SIZEGRIP, wxID_ANY) },
);

=item notebook

=cut

has notebook => (
    is      => 'ro',
    isa     => 'Wx::Notebook',
    lazy    => 1,
    default => sub {
        Wx::Notebook->new(shift, wxID_ANY,
            wxDefaultPosition, wxDefaultSize, 0),
    },
);

sub make_pages {
    my ($self) = @_;
    my @pages = (
        [ 'Search'               => $self->p_search,     1 ],
        [ 'Word'                 => $self->p_addword,    0 ],
        [ 'Words'                => $self->p_gridwords,  0 ],
        [ 'Irregular Verbs Test' => $self->pt_irrverbs,  0 ],
        [ 'TestSummary'          => $self->pts_irrverbs, 0 ],
        [ 'Translation Test'     => $self->pt_trans,     0 ],
        [ 'Test Editor'          => $self->p_testeditor, 0 ],
    );

    for my $page_item (@pages) {
        my ($caption, $page, $default) = @$page_item;
        $self->notebook->AddPage($page, $caption, $default);
    }
}

=item tran

=cut

has tran => (
    is      => 'ro',
    isa     => 'Dict::Learn::Translate',
    lazy    => 1,
    default => sub { Dict::Learn::Translate->new() },
);

=item p_search

=cut

has p_search => (
    is      => 'ro',
    isa     => 'Dict::Learn::Frame::SearchWords',
    lazy    => 1,
    default => sub {
        my $self = shift;
        Dict::Learn::Frame::SearchWords->new($self, $self->notebook,
            wxID_ANY, wxDefaultPosition, wxDefaultSize, wxTAB_TRAVERSAL)
    },
);

=item p_addword

=cut

has p_addword => (
    is      => 'ro',
    isa     => 'Dict::Learn::Frame::AddWord',
    lazy    => 1,
    default => sub {
        my $self = shift;
        Dict::Learn::Frame::AddWord->new($self, $self->notebook,
            wxID_ANY, wxDefaultPosition, wxDefaultSize, wxTAB_TRAVERSAL)
    },
);

=item p_gridwords

=cut

has p_gridwords => (
    is      => 'ro',
    isa     => 'Dict::Learn::Frame::GridWords',
    lazy    => 1,
    default => sub {
        my $self = shift;
        Dict::Learn::Frame::GridWords->new($self, $self->notebook,
            wxID_ANY, wxDefaultPosition, wxDefaultSize, wxTAB_TRAVERSAL)
    },
);

=item pt_irrverbs

=cut

has pt_irrverbs => (
    is      => 'ro',
    isa     => 'Dict::Learn::Frame::IrregularVerbsTest',
    lazy    => 1,
    default => sub {
        my $self = shift;
        Dict::Learn::Frame::IrregularVerbsTest->new($self, $self->notebook,
            wxID_ANY, wxDefaultPosition, wxDefaultSize, wxTAB_TRAVERSAL)
    },
);

=item pts_irrverbs

=cut

has pts_irrverbs => (
    is      => 'ro',
    isa     => 'Dict::Learn::Frame::TestSummary',
    lazy    => 1,
    default => sub {
        my $self = shift;
        Dict::Learn::Frame::TestSummary->new($self, $self->notebook,
            wxID_ANY, wxDefaultPosition, wxDefaultSize, wxTAB_TRAVERSAL)
    },
);

=item pt_trans

=cut

has pt_trans => (
    is      => 'ro',
    isa     => 'Dict::Learn::Frame::TranslationTest',
    lazy    => 1,
    default => sub {
        my $self = shift;
        Dict::Learn::Frame::TranslationTest->new($self, $self->notebook,
            wxID_ANY, wxDefaultPosition, wxDefaultSize, wxTAB_TRAVERSAL)
    },
);

=item p_testeditor

=cut

has p_testeditor => (
    is      => 'ro',
    isa     => 'Dict::Learn::Frame::TestEditor',
    lazy    => 1,
    default => sub {
        my $self = shift;
        Dict::Learn::Frame::TestEditor->new($self, $self->notebook,
            wxID_ANY, wxDefaultPosition, wxDefaultSize, wxTAB_TRAVERSAL)
    },
);

sub dictionary_check {
    my ($self, $event) = @_;

    # my $menu = $event->GetEventObject();
    my $menu_item = $self->menu_dicts->FindItem($event->GetId);
    $self->status_bar->SetStatusText(
        'Dictionary "' . $menu_item->GetLabel . '" selected');
    Dict::Learn::Dictionary->set(_DICT_ID($event->GetId));
    $self->set_frame_title(_DICT_ID($event->GetId));
}

sub set_tran_backend {
    my ($self, $event) = @_;

    my $menu_item = $self->menu_trans->FindItem($event->GetId);
    $self->status_bar->SetStatusText(
        'Use "' . $menu_item->GetLabel . '" translator');
    $self->tran->using($menu_item->GetLabel);
}

sub set_frame_title {
    my ($self, $id) = @_;

    $id ||= Dict::Learn::Dictionary->curr_id;
    $self->SetTitle(sprintf 'DictLearn - [%s]',
        Dict::Learn::Dictionary->get($id)->{dictionary_name});
}

sub on_close {
    my ($self, $event) = @_;

    print "exit\n";
    $self->Destroy;
}

sub db_export {
    my ($self) = @_;

    if (my $fn = Dict::Learn::Export->new->do()) {
        say "export [$fn]: successfully";
    }
    else {
        say 'export failed';
    }
}

sub db_import {
    my ($self) = @_;

    my $fileopen = Wx::FileDialog->new(
        $self,
        'Select a file',
        '', '',
        join('|',
            'JSON files (*.json)|*.json',
            'SQL files (*.sql)|*.sql',
            'All files (*.*)|*.*'),
        wxFD_OPEN
    );
    if ($fileopen->ShowModal == wxID_OK) {
        my $filename = $fileopen->GetPath();
        say "open filename: $filename";
        if (Dict::Learn::Import->new->do($filename)) {
            say 'import successfully';
        }
        else {
            say 'import failed';
        }
    }
}

sub db_clear {
    my ($self) = @_;

    $main::ioc->lookup('db')->clear_data();
}

sub db_clear_test_results {
    my ($self) = @_;

    $main::ioc->lookup('db')->clear_test_results();
}

sub analyze {
    my ($self) = @_;

    $main::ioc->lookup('db')->analyze();
}

sub reset_analyzer {
    my ($self) = @_;

    $main::ioc->lookup('db')->reset_analyzer();
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

    # main menu
    $self->SetMenuBar($self->menu_bar);

    $self->SetIcon(Wx::GetWxPerlIcon());
    $self->vbox->Add($self->notebook, 1, wxALL | wxEXPAND, 5);

    $self->make_pages();

    # tell we want automatic layout
    # $self->SetAutoLayout( 1 );
    $self->SetSizer($self->vbox);

    # size the window optimally and set its minimal size
    $self->Layout();
    $self->vbox->Fit( $self );
    # $self->vbox->SetSizeHints( $self );

    Dict::Learn::Dictionary->set(0);

    # set a frame title based on current dictionary
    # like 'DictLearn - [English-Ukrainian]'
    $self->set_frame_title();

    # events
    EVT_CLOSE($self, \&on_close);
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
