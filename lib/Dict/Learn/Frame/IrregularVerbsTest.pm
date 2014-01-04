package Dict::Learn::Frame::IrregularVerbsTest 0.1;

use Wx qw[:everything];
use Wx::Event qw[:everything];

use Moose;
use MooseX::NonMoose;
extends 'Wx::Panel';

use Const::Fast;
use Data::Printer;
use List::Util qw[shuffle];

use Database;
use Dict::Learn::Frame::IrregularVerbsTest::Result;

use common::sense;

const my $TEST_ID => 0;
const my $STEPS   => 10;

=head1 NAME

Dict::Learn::Frame::IrregularVerbsTest

=head1 DESCRIPTION

TODO add description

=head1 ATTRIBUTES

=head2 words

TODO add description

=cut

has words => (
    is      => 'rw',
    isa     => 'ArrayRef',
    lazy    => 1,
    default => sub { [] },
);

=head2 exercise

TODO add description

=cut

has exercise => (
    is      => 'rw',
    isa     => 'ArrayRef',
    lazy    => 1,
    default => sub { [] },
);

=head2 p_min

TODO add description

=cut

has p_min => (
    is      => 'rw',
    isa     => 'Int',
    lazy    => 1,
    default => 1,
);

=head2 p_max

TODO add description

=cut

has p_max => (
    is      => 'rw',
    isa     => 'Int',
    lazy    => 1,
    default => $STEPS,
);

=head2 p_current

TODO add description

=cut

has p_current => (
    is  => 'rw',
    isa => 'Int',
);

=head2 total_score

TODO add description

=cut

has total_score => (
    is      => 'rw',
    isa     => 'Int',
    default => 0,
);

=head2 parent

TODO add description

=cut

has parent => (
    is  => 'ro',
    isa => 'Dict::Learn::Frame',
);

=head2 l_position

TODO add description

=cut

has l_position => (
    is      => 'ro',
    isa     => 'Wx::StaticText',
    lazy    => 1,
    default => sub {
        Wx::StaticText->new(
            shift,         wxID_ANY,
            '1/' . $STEPS,  wxDefaultPosition,
            wxDefaultSize, wxALIGN_CENTRE
        )
    },
);

=head2 l_word

TODO add description

=cut

has l_word => (
    is      => 'ro',
    isa     => 'Wx::StaticText',
    lazy    => 1,
    default => sub {
        Wx::StaticText->new(
            shift,         wxID_ANY,
            'Word',        wxDefaultPosition,
            wxDefaultSize, wxALIGN_CENTRE
        )
    },
);

=head2 e_word2

TODO add description

=cut

has e_word2 => (
    is      => 'ro',
    isa     => 'Wx::TextCtrl',
    lazy    => 1,
    default => sub {
        Wx::TextCtrl->new(
            shift,         wxID_ANY,
            '',            wxDefaultPosition,
            wxDefaultSize, wxTE_LEFT
        )
    },
);

=head2 e_word3

TODO add description

=cut

has e_word3 => (
    is      => 'ro',
    isa     => 'Wx::TextCtrl',
    lazy    => 1,
    default => sub {
        Wx::TextCtrl->new(
            shift,         wxID_ANY,
            '',            wxDefaultPosition,
            wxDefaultSize, wxTE_LEFT
        )
    },
);

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

    my $hbox_words = Wx::BoxSizer->new(wxHORIZONTAL);
    $hbox_words->Add($self->l_word, 0,
        wxRIGHT | wxTOP | wxLEFT | wxEXPAND, 5);
    $hbox_words->Add($self->e_word2, 1, wxRIGHT | wxEXPAND, 5);
    $hbox_words->Add($self->e_word3, 1, wxEXPAND,           0);

    return $hbox_words;
}

=head2 res

TODO add description

=cut

has res => (
    is      => 'ro',
    isa     => 'Wx::StaticText',
    lazy    => 1,
    default => sub {
        Wx::StaticText->new(
            shift,         wxID_ANY,
            '',            wxDefaultPosition,
            wxDefaultSize, wxALIGN_CENTRE
        )
    },
);

=head2 res_word2

TODO add description

=cut

has res_word2 => (
    is      => 'ro',
    isa     => 'Wx::StaticText',
    lazy    => 1,
    default => sub {
        Wx::StaticText->new(
            shift,         wxID_ANY,
            '',            wxDefaultPosition,
            wxDefaultSize, wxALIGN_CENTRE
        )
    },
);

=head2 res_word3

TODO add description

=cut

has res_word3 => (
    is      => 'ro',
    isa     => 'Wx::StaticText',
    lazy    => 1,
    default => sub {
        Wx::StaticText->new(
            shift,         wxID_ANY,
            '',            wxDefaultPosition,
            wxDefaultSize, wxALIGN_CENTRE
        )
    },
);

=head2 hbox_res

TODO add description

=cut

has hbox_res => (
    is         => 'ro',
    isa        => 'Wx::BoxSizer',
    lazy_build => 1,
);

sub _build_hbox_res {
    my $self = shift;

    my $hbox_res = Wx::BoxSizer->new(wxHORIZONTAL);
    $hbox_res->Add($self->res, 0, wxRIGHT | wxTOP | wxLEFT | wxEXPAND, 5);
    $hbox_res->Add($self->res_word2, 1, wxRIGHT | wxEXPAND, 5);
    $hbox_res->Add($self->res_word3, 1, wxEXPAND,           0);

    return $hbox_res;
}

=head2 btn_prev

TODO add description

=cut

has btn_prev => (
    is      => 'ro',
    isa     => 'Wx::Button',
    lazy    => 1,
    default => sub {
        Wx::Button->new(shift, wxID_ANY, 'Prev', wxDefaultPosition,
            wxDefaultSize)
    },
);

=head2 btn_next

TODO add description

=cut

has btn_next => (
    is      => 'ro',
    isa     => 'Wx::Button',
    lazy    => 1,
    default => sub {
        Wx::Button->new(shift, wxID_ANY, 'Next', wxDefaultPosition,
            wxDefaultSize)
    },
);

=head2 btn_reset

TODO add description

=cut

has btn_reset => (
    is      => 'ro',
    isa     => 'Wx::Button',
    lazy    => 1,
    default => sub {
        Wx::Button->new(shift, wxID_ANY, 'Reset', wxDefaultPosition,
            wxDefaultSize)
    },
);

=head2 hbox_buttons

TODO add description

=cut

has hbox_buttons => (
    is         => 'ro',
    isa        => 'Wx::BoxSizer',
    lazy_build => 1,
);

sub _build_hbox_buttons {
    my $self = shift;

    my $hbox_buttons = Wx::BoxSizer->new(wxHORIZONTAL);
    $hbox_buttons->Add($self->btn_prev,  0, wxALL  | wxEXPAND,  0);
    $hbox_buttons->Add($self->btn_next,  0, wxALL  | wxEXPAND,  0);
    $hbox_buttons->Add($self->btn_reset, 0, wxLEFT | wxEXPAND, 40);

    return $hbox_buttons;
}

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
    $vbox->Add($self->l_position,   0, wxTOP | wxEXPAND, 5);
    $vbox->Add($self->hbox_words,   0, wxTOP | wxEXPAND, 20);
    $vbox->Add($self->hbox_res,     0, wxTOP | wxEXPAND, 5);
    $vbox->Add($self->hbox_buttons, 0, wxTOP | wxEXPAND, 20);

    return $vbox;
}

=head1 METHODS

=cut

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

    $self->SetSizer($self->vbox);
    $self->Layout();
    $self->vbox->Fit($self);

    $self->init_test();

    # events
    EVT_BUTTON($self, $self->btn_prev,  \&prev_word);
    EVT_BUTTON($self, $self->btn_next,  \&next_word);
    EVT_BUTTON($self, $self->btn_reset, \&reset_test);
    EVT_KEY_UP($self,          sub { $self->keybind($_[1]) });
    EVT_KEY_UP($self->e_word2, sub { $self->keybind2($_[1]) });
    EVT_KEY_UP($self->e_word3, sub { $self->keybind3($_[1]) });
}

=head2 keybind

TODO add description

=cut

sub keybind {
    my ($self, $event) = @_;

    # p($event);
    my $key = $event->GetKeyCode();
    if ($key == WXK_RETURN) {
        $self->next_word();
    }
}

=head2 keybind2

TODO add description

=cut

sub keybind2 {
    my ($self, $event) = @_;

    my $key = $event->GetKeyCode();
    if ($key == WXK_RETURN) {
        $self->e_word3->SetFocus();
    }
    elsif ($event->AltDown() and $key == WXK_BACK) {
        $self->prev_word();
    }
}

=head2 keybind3

TODO add description

=cut

sub keybind3 {
    my ($self, $event) = @_;

    my $key = $event->GetKeyCode();
    if ($event->GetKeyCode() == WXK_RETURN) {
        $self->next_word();
    }
    elsif ($event->AltDown() and $key == WXK_BACK) {
        $self->e_word2->SetFocus();
    }
}

=head2 get_word

TODO add description

=cut

sub get_word {
    my ($self, $id, $n) = @_;

    $n //= 1;
    my $words_c = scalar @{$self->words};
    return unless $words_c > 0;
    $id %= $words_c if $id >= $words_c;
    return unless defined $self->words->[$id];
    return $self->words->[$id];
}

=head2 get_step

TODO add description

=cut

sub get_step {
    my ($self, $id) = @_;

    return $self->exercise->[$id]
        if defined $self->exercise->[$id];
}

=head2 init_test

TODO add description

=cut

sub init_test {
    my ($self) = @_;

    $self->exercise([]);
    $self->clear_fields();
    $self->set_position($self->p_min);
    $self->words(
        [
            shuffle(
                Database->schema->resultset('Word')
                    ->get_irregular_verbs($STEPS)
            )
        ]
    );

    printf "Received %d verbs for test\n" => scalar @{$self->words};

    for my $id ($self->p_min - 1 .. $self->p_max - 1) {
        my $word = $self->get_word($id);
        push @{$self->exercise} => {
            word_id => $word->{word_id},
            word    => [$word->{word}, $word->{word2}, $word->{word3}],
            user    => [undef, [undef, 0], [undef, 0]],
            score   => undef,
            end     => 0,
        };
    }

    $self->load_step($self->p_current);
}

=head2 write_step_res

TODO add description

=cut

sub write_step_res {
    my ($self, $id, $end) = @_;

    $end //= 1;
    my $ex = $self->exercise->[$id - 1];
    $ex->{end} = $end;
    return if $ex->{score} and $ex->{score} >= 0;
    $ex->{user} = [
        undef,
        [
            $self->e_word2->GetValue => $self->e_word2->GetValue eq
                $ex->{word}[1] ? 0.5 : 0
        ],
        [
            $self->e_word3->GetValue => $self->e_word3->GetValue eq
                $ex->{word}[2] ? 0.5 : 0
        ]
    ];
    $ex->{score} = $ex->{user}[1][1] + $ex->{user}[2][1];
    $self->total_score($self->total_score + $ex->{score});
}

=head2 next_word

TODO add description

=cut

sub next_word {
    my ($self) = @_;

    $self->write_step_res($self->p_current);
    if ($self->p_current >= $self->p_max) {
        $self->result();
        return;
    }
    $self->clear_fields();
    $self->set_position($self->p_current + 1);
    $self->load_step($self->p_current);
}

=head2 prev_word

TODO add description

=cut

sub prev_word {
    my ($self) = @_;

    return unless $self->p_current > $self->p_min;
    $self->write_step_res($self->p_current, 0);
    $self->clear_fields();
    $self->set_position($self->p_current - 1);
    $self->load_step($self->p_current);
    $self->SetFocus();
}

=head2 set_position

TODO add description

=cut

sub set_position {
    my ($self, $position) = @_;

    $self->p_current($position);
    $self->l_position->SetLabel($self->p_current . '/' . $STEPS);
}

=head2 load_fields

TODO add description

=cut

sub load_fields {
    my ($self, $en, @words) = @_;

    $self->l_word->SetLabel($words[0])  if $words[0];
    $self->e_word2->SetValue($words[1]) if $words[1];
    $self->e_word3->SetValue($words[2]) if $words[2];
    $self->e_word2->Enable($en);
    $self->e_word3->Enable($en);
    $self->e_word2->SetFocus();
    $self->Layout();
}

=head2 load_step

TODO add description

=cut

sub load_step {
    my ($self, $id) = @_;

    my $step = $self->get_step($id - 1);
    $self->load_fields(
        !$step->{end},       $step->{word}[0],
        $step->{user}[1][0], $step->{user}[2][0]
    );
}

=head2 clear_fields

TODO add description

=cut

sub clear_fields {
    my ($self) = @_;

    $self->l_word->SetLabel('');
    $self->e_word2->Clear;
    $self->e_word3->Clear;
    $self->Layout();
}

=head2 reset_test

TODO add description

=cut

sub reset_test {
    my ($self) = @_;

    $self->init_test();
}

=head2 result

TODO add description

=cut

sub result {
    my ($self) = @_;

    my $result_dialog
        = Dict::Learn::Frame::IrregularVerbsTest::Result->new($self,
        wxID_ANY, 'Result', wxDefaultPosition, wxDefaultSize,
        wxDEFAULT_DIALOG_STYLE | wxRESIZE_BORDER | wxSTAY_ON_TOP);
    if ($result_dialog->fill_result($self->exercise)->ShowModal() == wxID_OK)
    {
        Database->schema->resultset('TestSession')
            ->add($TEST_ID, $self->total_score, $self->exercise);
    }
    $result_dialog->Destroy();
    $self->reset_test();

    # if TestSummary is displayed, reload its data
    $self->parent->for_each_page(
        sub {
            my ($i, $page) = @_;

            return unless ref $page eq 'Dict::Learn::Frame::TestSummary';

            $page->refresh_data();
        }
    );
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
