package Dict::Learn::Frame 0.1;

use Wx qw[:everything];
use Wx::AUI;
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

=item manager

=cut

has manager => (
    is      => 'ro',
    isa     => 'Wx::AuiManager',
    lazy    => 1,
    default => sub { Wx::AuiManager->new },
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

=item menu_word

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
        [ 'Add'  => \&p_addword   => 'Ctrl+N' ],
        [ "Grid" => \&p_gridwords => 'Ctrl+G' ],
    );

    for my $menu_item (@menu) {
        my ($caption, $coderef, $keybind) = @$menu_item;
        my $menu_id = $self->next_menu_id;
        $menu_word->Append($menu_id,
            $caption . ($keybind ? "\t" . $keybind : ''));

        EVT_MENU($self, $menu_id,
            sub { $self->new_page($self->$coderef(), $caption) });
    }

    return $menu_word;
}

=item menu_test

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
        [ 'Test Editor'          => \&p_testeditor   => 'Ctrl+E' ],
    );

    for my $menu_item (@menu) {
        my ($caption, $coderef, $keybind) = @$menu_item;
        my $menu_id = $self->next_menu_id;
        $menu_test->Append($menu_id,
            $caption . ($keybind ? "\t" . $keybind : ''));

        EVT_MENU($self, $menu_id,
            sub { $self->new_page($self->$coderef(), $caption) });
    }

    return $menu_test;
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

=item menu_translate

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
        my $menu_id = $self->next_menu_id;
        $menu_translate->AppendRadioItem($menu_id, $translator_backend);
        EVT_MENU($self, $menu_id, \&set_translator_backend);
    }

    return $menu_translate
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

sub make_pages {
    my ($self) = @_;

    my @pages = (
        [ 'Search'               => $self->p_search,     1 ],
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

=item translator

=cut

has translator => (
    is      => 'ro',
    isa     => 'Dict::Learn::Translate',
    lazy    => 1,
    default => sub { Dict::Learn::Translate->new() },
);

=item p_search

=cut

sub p_search {
    my $self = shift;

    return Dict::Learn::Frame::SearchWords->new($self, $self->notebook,
        wxID_ANY, wxDefaultPosition, wxDefaultSize, wxTAB_TRAVERSAL)
}

=item p_addword

=cut

sub p_addword {
    my $self = shift;

    return Dict::Learn::Frame::AddWord->new($self, $self->notebook,
        wxID_ANY, wxDefaultPosition, wxDefaultSize, wxTAB_TRAVERSAL)
}

=item p_gridwords

=cut

sub p_gridwords {
    my $self = shift;

    return Dict::Learn::Frame::GridWords->new($self, $self->notebook,
        wxID_ANY, wxDefaultPosition, wxDefaultSize, wxTAB_TRAVERSAL)
}

=item pt_irrverbs

=cut

sub pt_irrverbs {
    my $self = shift;

    return Dict::Learn::Frame::IrregularVerbsTest->new($self, $self->notebook,
        wxID_ANY, wxDefaultPosition, wxDefaultSize, wxTAB_TRAVERSAL)
}

=item pts_irrverbs

=cut

sub pts_irrverbs {
    my $self = shift;

    return Dict::Learn::Frame::TestSummary->new($self, $self->notebook,
        wxID_ANY, wxDefaultPosition, wxDefaultSize, wxTAB_TRAVERSAL);
}

=item pt_translation

=cut

sub pt_translation {
    my $self = shift;

    return Dict::Learn::Frame::TranslationTest->new($self, $self->notebook,
        wxID_ANY, wxDefaultPosition, wxDefaultSize, wxTAB_TRAVERSAL)
}

=item p_testeditor

=cut

sub p_testeditor {
    my $self = shift;

    return Dict::Learn::Frame::TestEditor->new($self, $self->notebook,
        wxID_ANY, wxDefaultPosition, wxDefaultSize, wxTAB_TRAVERSAL)
}

sub new_page {
    my ($self, $panel_ref, $caption, $default) = @_;

    $self->notebook->AddPage($panel_ref, $caption, $default // 1);
}

sub dictionary_check {
    my ($self, $event) = @_;

    # my $menu = $event->GetEventObject();
    my $menu_item = $self->menu_dicts->FindItem($event->GetId);
    $self->status_bar->SetStatusText(
        'Dictionary "' . $menu_item->GetLabel . '" selected');
    Dict::Learn::Dictionary->set(_DICT_ID($event->GetId));
    $self->set_frame_title(_DICT_ID($event->GetId));
}

sub set_translator_backend {
    my ($self, $event) = @_;

    my $menu_item = $self->menu_translate->FindItem($event->GetId);
    $self->status_bar->SetStatusText(
        'Use "' . $menu_item->GetLabel . '" translator');
    $self->translator->using($menu_item->GetLabel);
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

    Container->lookup('db')->clear_data();
}

sub db_clear_test_results {
    my ($self) = @_;

    Container->lookup('db')->clear_test_results();
}

sub analyze {
    my ($self) = @_;

    Container->lookup('db')->analyze();
}

sub reset_analyzer {
    my ($self) = @_;

    Container->lookup('db')->reset_analyzer();
}

sub for_each_page {
    my ($self, $cb) = @_;

    die q{$cb isn't a coderef} unless ref $cb eq 'CODE';

    for my $i (0 .. $self->notebook->GetPageCount()) {
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
