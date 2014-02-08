package Dict::Learn::Frame;

use Wx qw[:everything];
use Wx::AUI;
use Wx::Grid;
use Wx::Event qw[:everything];

use Moose;
use MooseX::NonMoose;
extends 'Wx::Frame';

use Carp qw[ croak confess ];
use Const::Fast;
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
use Dict::Learn::Frame::PrepositionTest;
use Dict::Learn::Import;

# A hardcoded offset to distinguish dictionaries IDs from other IDs
const my $DICT_OFFSET => 100;

=head1 NAME

Dict::Learn::Frame

=head1 DESCRIPTION

TODO add description

=cut

# Returns MENU_ID including offset
sub _MENU_ID { int(shift) + $DICT_OFFSET }

# Returns DICT_ID including offset
sub _DICT_ID { int(shift) - $DICT_OFFSET }

sub _next_menu_id {
    state $menu_id = 0; $menu_id++
}

=head1 ATTRIBUTES

=head2 parent

TODO add description

=cut

has parent => ( is => 'ro' );

=head2 manager

TODO add description

=cut

has manager => (
    is      => 'ro',
    isa     => 'Wx::AuiManager',
    lazy    => 1,
    default => sub { Wx::AuiManager->new },
);

=head2 menu_bar

TODO add description

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
        [ Dictionaries => $self->menu_dicts     ],
        [ Word         => $self->menu_word      ],
        [ Test         => $self->menu_test      ],
        [ DB           => $self->menu_db        ],
        [ Translate    => $self->menu_translate ],
    );

    for my $menu_item (@menu) {
        my ($caption, $menu_ref) = @$menu_item;
        $menubar->Append($menu_ref, $caption);
    }

    $menubar
}

=head2 menu_dicts

TODO add description

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

=head2 menu_word

TODO add description

=cut

has menu_word => (
    is         => 'ro',
    isa        => 'Wx::Menu',
    lazy_build => 1,
);

sub _build_menu_word {
    my ($self) = @_;
    my $menu_word = Wx::Menu->new;

    my @menu = (
        ['Add'    => \&p_addword   => 'Ctrl+N'],
        ["Grid"   => \&p_gridwords            ],
        ["Search" => \&p_search    => 'Ctrl+F'],
    );

    for my $menu_item (@menu) {
        my ($caption, $coderef, $keybind) = @$menu_item;
        my $menu_id = $self->_next_menu_id;
        $menu_word->Append($menu_id,
            $caption . ($keybind ? "\t" . $keybind : ''));

        EVT_MENU($self, $menu_id,
            sub { $self->new_page($self->$coderef(), $caption) });
    }

    return $menu_word;
}

=head2 menu_test

TODO add description

=cut

has menu_test => (
    is         => 'ro',
    isa        => 'Wx::Menu',
    lazy_build => 1,
);

sub _build_menu_test {
    my ($self) = @_;
    my $menu_test = Wx::Menu->new;

    my @menu = (
        [ 'Irregular Verbs Test' => \&pt_irrverbs    => 'Ctrl+I' ],
        [ 'Test Summary'         => \&pts_irrverbs   => 'Ctrl+S' ],
        [ 'Translation Test'     => \&pt_translation => 'Ctrl+T' ],
        [ 'Preposition Test'     => \&pt_preposition => 'Ctrl+P' ],
        [ 'Test Editor'          => \&p_testeditor   => 'Ctrl+E' ],
    );

    for my $menu_item (@menu) {
        my ($caption, $coderef, $keybind) = @$menu_item;
        my $menu_id = $self->_next_menu_id;
        $menu_test->Append($menu_id,
            $caption . ($keybind ? "\t" . $keybind : ''));

        EVT_MENU($self, $menu_id,
            sub { $self->new_page($self->$coderef(), $caption) });
    }

    return $menu_test;
}

=head2 menu_db

TODO add description

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
        my $menu_id = $self->_next_menu_id;
        $menu_db->Append($menu_id, $caption);
        EVT_MENU($self, $menu_id, $coderef);
    }

    $menu_db
}

=head2 menu_translate

TODO add description

=cut

has menu_translate => (
    is         => 'ro',
    isa        => 'Wx::Menu',
    lazy_build => 1,
);

sub _build_menu_translate {
    my ($self) = @_;
    my $menu_translate = Wx::Menu->new;

    for my $translator_backend (@{ $self->translator->get_backends_list }) {
        my $menu_id = $self->_next_menu_id;
        $menu_translate->AppendRadioItem($menu_id, $translator_backend);
        EVT_MENU($self, $menu_id, \&set_translator_backend);
    }

    return $menu_translate
}

=head2 status_bar

TODO add description

=cut

has status_bar => (
    is      => 'ro',
    lazy    => 1,
    default => sub { shift->CreateStatusBar(1, wxST_SIZEGRIP, wxID_ANY) },
);

=head2 notebook

=cut

has notebook => (
    is      => 'ro',
    isa     => 'Wx::AuiNotebook',
    lazy    => 1,
    default => sub {
        Wx::AuiNotebook->new(
            shift, wxID_ANY, wxDefaultPosition, wxDefaultSize,
            wxAUI_NB_TAB_MOVE | wxAUI_NB_SCROLL_BUTTONS
                | wxAUI_NB_CLOSE_ON_ALL_TABS | wxAUI_NB_TOP
        ),
    },
);

=head2 translator

TODO add description

=cut

has translator => (
    is      => 'ro',
    isa     => 'Dict::Learn::Translate',
    lazy    => 1,
    default => sub { Dict::Learn::Translate->new() },
);

=head1 METHODS

=head2 make_pages

TODO add description

=cut

sub make_pages {
    my ($self) = @_;

    my @pages = (
        # [ 'Search'               => $self->p_search,       1 ],
        # [ 'Word'                 => $self->p_addword,      0 ],
        # [ 'Words'                => $self->p_gridwords,    0 ],
        # [ 'Irregular Verbs Test' => $self->pt_irrverbs,    0 ],
        # [ 'TestSummary'          => $self->pts_irrverbs,   0 ],
        # [ 'Translation Test'     => $self->pt_translation, 0 ],
        # [ 'Test Editor'          => $self->p_testeditor,   0 ],
    );

    for my $page_item (@pages) {
        my ($caption, $page, $default) = @$page_item;
        $self->new_page($page, $caption, $default);
    }
}

=head2 p_search

TODO add description

=cut

sub p_search {
    my $self = shift;

    return Dict::Learn::Frame::SearchWords->new($self, $self->notebook,
        wxID_ANY, wxDefaultPosition, wxDefaultSize, wxTAB_TRAVERSAL)
}

=head2 p_addword

TODO add description

=cut

sub p_addword {
    my $self = shift;

    return Dict::Learn::Frame::AddWord->new($self, $self->notebook,
        wxID_ANY, wxDefaultPosition, wxDefaultSize, wxTAB_TRAVERSAL)
}

=head2 p_gridwords

TODO add description

=cut

sub p_gridwords {
    my $self = shift;

    return Dict::Learn::Frame::GridWords->new($self, $self->notebook,
        wxID_ANY, wxDefaultPosition, wxDefaultSize, wxTAB_TRAVERSAL)
}

=head2 pt_irrverbs

TODO add description

=cut

sub pt_irrverbs {
    my $self = shift;

    return Dict::Learn::Frame::IrregularVerbsTest->new($self, $self->notebook,
        wxID_ANY, wxDefaultPosition, wxDefaultSize, wxTAB_TRAVERSAL)
}

=head2 pts_irrverbs

TODO add description

=cut

sub pts_irrverbs {
    my $self = shift;

    return Dict::Learn::Frame::TestSummary->new($self, $self->notebook,
        wxID_ANY, wxDefaultPosition, wxDefaultSize, wxTAB_TRAVERSAL);
}

=head2 pt_translation

TODO add description

=cut

sub pt_translation {
    my $self = shift;

    return Dict::Learn::Frame::TranslationTest->new($self, $self->notebook,
        wxID_ANY, wxDefaultPosition, wxDefaultSize, wxTAB_TRAVERSAL)
}

=head2 pt_preposition

Exercise on Prepositions

=cut

sub pt_preposition {
    my $self = shift;

    return Dict::Learn::Frame::PrepositionTest->new($self, $self->notebook,
        wxID_ANY, wxDefaultPosition, wxDefaultSize, wxTAB_TRAVERSAL)
}

=head2 p_testeditor

TODO add description

=cut

sub p_testeditor {
    my $self = shift;

    return Dict::Learn::Frame::TestEditor->new($self, $self->notebook,
        wxID_ANY, wxDefaultPosition, wxDefaultSize, wxTAB_TRAVERSAL)
}

=head2 new_page

TODO add description

=cut

sub new_page {
    my ($self, $panel_ref, $caption, $default) = @_;

    $self->notebook->AddPage($panel_ref, $caption, $default // 1);
}

=head2 dictionary_check

TODO add description

=cut

sub dictionary_check {
    my ($self, $event) = @_;

    # my $menu = $event->GetEventObject();
    my $menu_item = $self->menu_dicts->FindItem($event->GetId);
    $self->status_bar->SetStatusText(
        'Dictionary "' . $menu_item->GetLabel . '" selected');
    Dict::Learn::Dictionary->set(_DICT_ID($event->GetId));
    $self->set_frame_title(_DICT_ID($event->GetId));
}

=head2 set_translator_backend

TODO add description

=cut

sub set_translator_backend {
    my ($self, $event) = @_;

    my $menu_item = $self->menu_translate->FindItem($event->GetId);
    $self->status_bar->SetStatusText(
        'Use "' . $menu_item->GetLabel . '" translator');
    $self->translator->using($menu_item->GetLabel);
}

=head2 set_frame_title

TODO add description

=cut

sub set_frame_title {
    my ($self, $id) = @_;

    $id ||= Dict::Learn::Dictionary->curr_id;
    $self->SetTitle(sprintf 'DictLearn - [%s]',
        Dict::Learn::Dictionary->get($id)->{dictionary_name});
}

=head2 on_close

TODO add description

=cut

sub on_close {
    my ($self, $event) = @_;

    print "exit\n";
    $self->Destroy;
}

=head2 db_export

TODO add description

=cut

sub db_export {
    my ($self) = @_;

    if (my $fn = Dict::Learn::Export->new->do()) {
        say "export [$fn]: successfully";
    }
    else {
        say 'export failed';
    }
}

=head2 db_import

TODO add description

=cut

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

=head2 db_clear

TODO add description

=cut

sub db_clear {
    my ($self) = @_;

    Container->lookup('db')->clear_data();
}

=head2 db_clear_test_results

TODO add description

=cut

sub db_clear_test_results {
    my ($self) = @_;

    Container->lookup('db')->clear_test_results();
}

=head2 analyze

TODO add description

=cut

sub analyze {
    my ($self) = @_;

    Container->lookup('db')->analyze();
}

=head2 reset_analyzer

TODO add description

=cut

sub reset_analyzer {
    my ($self) = @_;

    Container->lookup('db')->reset_analyzer();
}

=head2 for_each_page

TODO add description

=cut

sub for_each_page {
    my ($self, $cb) = @_;

    die q{$cb isn't a coderef} unless ref $cb eq 'CODE';

    for my $i (0 .. $self->notebook->GetPageCount() - 1) {
        $cb->($i => $self->notebook->GetPage($i));
    }
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

    $self->manager->SetManagedWindow($self);
    $self->SetIcon(Wx::GetWxPerlIcon());

    $self->make_pages();

    $self->manager->AddPane($self->notebook,
        Wx::AuiPaneInfo->new->Name("notebook")
            ->CenterPane->Caption("Notebook")->Position(1)
    );

    Dict::Learn::Dictionary->set(0);

    # set a frame title based on current dictionary
    # like 'DictLearn - [English-Ukrainian]'
    $self->set_frame_title();

    $self->manager->Update;

    # events
    EVT_CLOSE($self, \&on_close);
}

sub DESTROY {
    my ($self) = @_;

    $self->manager->UnInit;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
