package Dict::Learn::Frame 0.1;

use Wx qw[:everything];
use Wx::Grid;
use Wx::Event qw[:everything];

use base 'Wx::Frame';

use Data::Printer;

use File::Basename 'dirname';
use lib dirname(__FILE__) . '/../lib/';

use Dict::Learn::Db;
use Dict::Learn::Export;
use Dict::Learn::Import;
use Dict::Learn::Frame::AddWord;
use Dict::Learn::Frame::AddExample;
use Dict::Learn::Frame::GridWords;
use Dict::Learn::Frame::GridExamples;
use Dict::Learn::Frame::SearchWords;
use Dict::Learn::Frame::IrregularVerbsTest;
use Dict::Learn::Frame::TestSummary;
use Dict::Learn::Frame::TranslationTest;

use common::sense;

use Class::XSAccessor accessors => [
    qw| parent
        vbox menu_bar menu_dicts menu_db menu_trans
        status_bar notebook
        p_additem p_addword p_addexample p_gridwords p_search
        p_gridexamples
        pt_irrverbs
        pts_irrverbs
        pt_trans
        tran
      |
];

use constant DICT_OFFSET => 100;

sub new {
    my ($class, $parent) = @_;
    my $self = $class->SUPER::new(splice @_ => 1);
    $self->parent($parent);
    $self->SetIcon(Wx::GetWxPerlIcon());
    $self->vbox(Wx::BoxSizer->new(wxVERTICAL));
    $self->notebook(
        Wx::Notebook->new(
            $self, wxID_ANY, wxDefaultPosition, wxDefaultSize, 0
        )
    );

    $self->tran(Dict::Learn::Translate->new());

    # main menu
    my $menu_id = 0;
    $self->menu_bar(Wx::MenuBar->new(0));
    $self->SetMenuBar($self->menu_bar);
    $self->menu_dicts(Wx::Menu->new);
    $self->menu_bar->Append($self->menu_dicts, 'Dictionaries');
    $self->init_menu_dicts($self->menu_dicts);
    $self->menu_db(Wx::Menu->new);
    $self->menu_bar->Append($self->menu_db, 'DB');
    $self->menu_db->Append(++$menu_id, 'Export');
    EVT_MENU($self, $menu_id, \&db_export);
    $self->menu_db->Append(++$menu_id, 'Import');
    EVT_MENU($self, $menu_id, \&db_import);
    $self->menu_db->Append(++$menu_id, 'Clear All Data');
    EVT_MENU($self, $menu_id, \&db_clear);
    $self->menu_db->Append(++$menu_id, 'Clear Test Results');
    EVT_MENU($self, $menu_id, \&db_clear_test_results);
    $self->menu_db->Append(++$menu_id, 'Analyze');
    EVT_MENU($self, $menu_id, \&analyze);
    $self->menu_db->Append(++$menu_id, 'Reset Analyzer');
    EVT_MENU($self, $menu_id, \&reset_analyzer);
    $self->menu_trans(Wx::Menu->new);
    $self->menu_bar->Append($self->menu_trans, 'Translate');
    $self->init_menu_translate($self->menu_trans, $menu_id);

    # panel search

    $self->p_search(
        Dict::Learn::Frame::SearchWords->new(
            $self,         $self->notebook,
            wxID_ANY,      wxDefaultPosition,
            wxDefaultSize, wxTAB_TRAVERSAL
        )
    );
    $self->notebook->AddPage($self->p_search, "Search", 1);

    # panel addword

    $self->p_addword(
        Dict::Learn::Frame::AddWord->new(
            $self,         $self->notebook,
            wxID_ANY,      wxDefaultPosition,
            wxDefaultSize, wxTAB_TRAVERSAL
        )
    );

    $self->notebook->AddPage($self->p_addword, "Word", 0);

    # panel addexample

    $self->p_addexample(
        Dict::Learn::Frame::AddExample->new(
            $self,         $self->notebook,
            wxID_ANY,      wxDefaultPosition,
            wxDefaultSize, wxTAB_TRAVERSAL
        )
    );

    $self->notebook->AddPage($self->p_addexample, "Example", 0);

    # panel: table of words

    $self->p_gridwords(
        Dict::Learn::Frame::GridWords->new(
            $self,         $self->notebook,
            wxID_ANY,      wxDefaultPosition,
            wxDefaultSize, wxTAB_TRAVERSAL
        )
    );
    $self->notebook->AddPage($self->p_gridwords, "Words", 0);

    # panel: table of examples

    $self->p_gridexamples(
        Dict::Learn::Frame::GridExamples->new(
            $self,         $self->notebook,
            wxID_ANY,      wxDefaultPosition,
            wxDefaultSize, wxTAB_TRAVERSAL
        )
    );
    $self->notebook->AddPage($self->p_gridexamples, "Examples", 0);

    # Irregular Verbs test
    $self->pt_irrverbs(
        Dict::Learn::Frame::IrregularVerbsTest->new(
            $self,         $self->notebook,
            wxID_ANY,      wxDefaultPosition,
            wxDefaultSize, wxTAB_TRAVERSAL
        )
    );
    $self->notebook->AddPage($self->pt_irrverbs, "Irregular Verbs Test", 0);

    # Test Summary
    $self->pts_irrverbs(
        Dict::Learn::Frame::TestSummary->new(
            $self,         $self->notebook,
            wxID_ANY,      wxDefaultPosition,
            wxDefaultSize, wxTAB_TRAVERSAL
        )
    );
    $self->notebook->AddPage($self->pts_irrverbs, "TestSummary", 0);

    # Translation Test
    $self->pt_trans(
        Dict::Learn::Frame::TranslationTest->new(
            $self,         $self->notebook,
            wxID_ANY,      wxDefaultPosition,
            wxDefaultSize, wxTAB_TRAVERSAL
        )
    );
    $self->notebook->AddPage($self->pt_trans, "Translation Test", 0);

    # tell we want automatic layout
    # $self->SetAutoLayout( 1 );
    $self->vbox->Add($self->notebook, 1, wxALL | wxEXPAND, 5);
    $self->SetSizer($self->vbox);

    # size the window optimally and set its minimal size
    # $self->vbox->Fit( $self );
    # $self->vbox->SetSizeHints( $self );
    $self->status_bar($self->CreateStatusBar(1, wxST_SIZEGRIP, wxID_ANY));

    Dict::Learn::Dictionary->set(0);

    # set a frame title based on current dictionary
    # like 'DictLearn - [English-Ukrainian]'
    $self->set_frame_title();

    # events
    EVT_CLOSE($self, \&on_close);
    $self;
}

sub init_menu_dicts {
    my ($self, $menu) = @_;

    # Wx::MenuItem->new( $self->menu_dicts, wxID_ANY, "Test", "", wxITEM_NORMAL)
    for (sort { $a->{dictionary_id} <=> $b->{dictionary_id} }
        values %{Dict::Learn::Dictionary->all})
    {
        $menu->AppendRadioItem(_MENU_ID($_->{dictionary_id}),
            $_->{dictionary_name});

        # event
        EVT_MENU($self, _MENU_ID($_->{dictionary_id}), \&dictionary_check);
    }
    $self;
}

sub init_menu_translate {
    my ($self, $menu, $menu_id) = @_;
    for my $tran_backend (@{$self->tran->get_backends_list}) {
        $self->menu_trans->AppendRadioItem(++$menu_id, $tran_backend);
        EVT_MENU($self, $menu_id, \&set_tran_backend);
    }
}

sub dictionary_check {
    my ($self, $event) = @_;

    # my $menu = $event->GetEventObject();
    my $menu_item = $self->menu_dicts->FindItem($event->GetId);
    $self->status_bar->SetStatusText(
        "Dictionary '" . $menu_item->GetLabel . "' selected");
    Dict::Learn::Dictionary->set(_DICT_ID($event->GetId));
    $self->set_frame_title(_DICT_ID($event->GetId));
}

sub set_tran_backend {
    my ($self, $event) = @_;
    my $menu_item = $self->menu_trans->FindItem($event->GetId);
    $self->status_bar->SetStatusText(
        "Use '" . $menu_item->GetLabel . "' translator");
    $self->tran->using($menu_item->GetLabel);
}

sub set_frame_title {
    my ($self, $id) = @_;
    $id ||= Dict::Learn::Dictionary->curr_id;
    $self->SetTitle(sprintf 'DictLearn - [%s]',
        Dict::Learn::Dictionary->get($id)->{dictionary_name});
}

sub _MENU_ID {
    my ($dict_id) = @_;
    int($dict_id) + DICT_OFFSET;
}

sub _DICT_ID {
    my ($menu_id) = @_;
    int($menu_id) - DICT_OFFSET;
}

sub on_close {
    my ($self, $event) = @_;
    print "exit\n";
    $self->Destroy;
}

sub db_export {
    my ($self) = @_;
    if (my $fn = Dict::Learn::Export->new->do()) {
        say "export [" . $fn . "]: successfully";
    }
    else {
        say "export failed";
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
        say "open filename: " . $filename;
        if (Dict::Learn::Import->new->do($filename)) {
            say "import successfully";
        }
        else {
            say "import failed";
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

1;
