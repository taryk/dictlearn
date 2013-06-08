package Dict::Learn::Frame::TranslationTest 0.1;

use Wx qw[:everything];
use Wx::Event qw[:everything];

use Data::Printer;

use Moose;
use MooseX::NonMoose;
extends 'Wx::Panel';

use Dict::Learn::Dictionary;
use Dict::Learn::Frame::TranslationTest::Result;

use List::Util qw[ shuffle reduce sum ];

use String::Diff qw[ diff_fully diff diff_merge ];

use common::sense;

# use warnings FATAL => "all";

sub TEST_ID { 1 }

has STEPS => (is => 'ro', default => sub {3});
has min   => (is => 'ro', default => sub {1});
has max   => (
    is      => 'rw',
    default => sub { $_[0]->STEPS },
    trigger => sub {
        my ($self, $new_index, $prev_index) = @_;
        unless (defined $self->exercise->[$new_index]) {
            my $last_index = $#{$self->exercise} + 1;
            return unless $new_index >= $last_index;
            $self->fetch_exercises($last_index, $new_index);
        }
    },
);

has total_score => (
    is      => 'rw',
    default => sub {0},
    clearer => 'clear_score',
);

has exercise => (
    is      => 'rw',
    default => sub { [] },
    clearer => 'clear_exercise',
);

has parent => (
    is  => 'ro',
    isa => 'Dict::Learn::Frame',
);

has hbox => (
    is      => 'ro',
    isa     => 'Wx::BoxSizer',
    default => sub { Wx::BoxSizer->new(wxHORIZONTAL) },
);

has hbox_position => (
    is      => 'ro',
    isa     => 'Wx::BoxSizer',
    default => sub { Wx::BoxSizer->new(wxHORIZONTAL) },
);

has vbox => (
    is      => 'ro',
    isa     => 'Wx::BoxSizer',
    default => sub { Wx::BoxSizer->new(wxVERTICAL) },
);

has pos => (
    is      => 'rw',
    isa     => 'Int',
    default => sub { shift->min },
    trigger => sub {
        my ($self, $pos) = @_;
        $self->set_position($pos);
    },
);

has position => (
    is      => 'ro',
    isa     => 'Wx::StaticText',
    default => sub {
        my ($self) = @_;
        Wx::StaticText->new($self, wxID_ANY, $self->min . '/',
            wxDefaultPosition, wxDefaultSize, wxALIGN_CENTRE);
    },
);

has spin => (
    is      => 'ro',
    isa     => 'Wx::SpinCtrl',
    default => sub {
        Wx::SpinCtrl->new($_[0], wxID_ANY, 0, wxDefaultPosition,
            wxDefaultSize, wxSP_ARROW_KEYS | wxSP_WRAP);
    },
);

has text => (
    is      => 'ro',
    isa     => 'Wx::StaticText',
    default => sub {
        Wx::StaticText->new($_[0], wxID_ANY, '', wxDefaultPosition,
            wxDefaultSize, wxALIGN_CENTRE);
    },
);

has input => (
    is      => 'ro',
    isa     => 'Wx::TextCtrl',
    default => sub {
        Wx::TextCtrl->new($_[0], wxID_ANY, '', wxDefaultPosition,
            wxDefaultSize, wxTE_LEFT);
    },
);

has btn_prev => (
    is      => 'ro',
    isa     => 'Wx::Button',
    default => sub {
        Wx::Button->new($_[0], wxID_ANY, 'Prev', wxDefaultPosition,
            wxDefaultSize);
    },
);

has btn_next => (
    is      => 'ro',
    isa     => 'Wx::Button',
    default => sub {
        Wx::Button->new($_[0], wxID_ANY, 'Next', wxDefaultPosition,
            wxDefaultSize);
    },
);

has btn_reset => (
    is      => 'ro',
    isa     => 'Wx::Button',
    default => sub {
        Wx::Button->new($_[0], wxID_ANY, 'Reset', wxDefaultPosition,
            wxDefaultSize);
    },
);

has result => (
    is         => 'ro',
    isa        => 'Dict::Learn::Frame::TranslationTest::Result',
    lazy_build => 1,
);

sub _build_result {
    Dict::Learn::Frame::TranslationTest::Result->new(
        $_[0], wxID_ANY, 'Result', wxDefaultPosition,
        [800, 600],
        wxDEFAULT_DIALOG_STYLE | wxRESIZE_BORDER | wxSTAY_ON_TOP
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
    $self->hbox->Add($self->btn_prev,  0, wxALL | wxGROW,  0);
    $self->hbox->Add($self->btn_next,  0, wxALL | wxGROW,  0);
    $self->hbox->Add($self->btn_reset, 0, wxLEFT | wxGROW, 40);

    $self->hbox_position->Add($self->position, 0, wxGROW, 0);
    $self->hbox_position->Add($self->spin,     0, wxGROW, 0);
    $self->spin->SetRange(2, 100);
    $self->spin->SetValue(3);

    $self->vbox->Add($self->hbox_position, 0, wxTOP | wxGROW, 5);
    $self->vbox->Add($self->text,          0, wxTOP | wxGROW, 20);
    $self->vbox->Add($self->input,         0, wxTOP | wxGROW, 5);
    $self->vbox->Add($self->hbox,          0, wxTOP | wxGROW, 20);
    $self->SetSizer($self->vbox);
    $self->Layout();
    $self->vbox->Fit($self);

    # events
    EVT_BUTTON($self, $self->btn_prev,  \&prev_step);
    EVT_BUTTON($self, $self->btn_next,  \&next_step);
    EVT_BUTTON($self, $self->btn_reset, \&reset_session);

    EVT_SPINCTRL($self, $self->spin, \&spin_max_step);

    EVT_KEY_UP($self,        sub { $self->keybind($_[1]) });
    EVT_KEY_UP($self->input, sub { $self->keybind2($_[1]) });

    Dict::Learn::Dictionary->cb(
        sub {
            $self->init();
        }
    );
}

sub keybind {
    my ($self, $event) = @_;
    $self->next_step()
        if $event->GetKeyCode() == WXK_RETURN;
}

sub keybind2 {
    my ($self, $event) = @_;
    my $key = $event->GetKeyCode();
    if ($key == WXK_RETURN) {
        $self->next_step();
    }
    elsif ($event->AltDown() and $key == WXK_BACK) {
        $self->prev_step();
    }
}

sub spin_max_step {
    my ($self, $event) = @_;
    $self->max($event->GetInt);
}

{
    my @ids;

    sub load_exercise_ids {
        my ($self) = @_;

        # let's get all ids
        my $id_rs
            = $main::ioc->lookup('db')->schema->resultset('Word')->search(
            {   'me.in_test'       => 1,
                'word2_id.in_test' => 1,
                'me.lang_id' =>
                    Dict::Learn::Dictionary->curr->{language_orig_id}
                    {language_id},
            },
            {   select => ['word_id'],
                join   => {'rel_words' => ['word2_id']}
            }
            );
        $id_rs->result_class('DBIx::Class::ResultClass::HashRefInflator');

        @ids = shuffle map { $_->{word_id} } ($id_rs->all());
    }

    sub fetch_exercises {
        my ($self, $from, $to) = @_;
        say "fetching exercises from $from to $to";
        my $words
            = $main::ioc->lookup('db')->schema->resultset('Word')
            ->search({'me.word_id' => {in => [@ids[$from .. $to]]}},
            {distinct => 1});
        while (my $word = $words->next) {
            push @{$self->exercise},
                [
                $word->word_id, $word->word, undef,
                [map { [$_->word_id, $_->word] } $word->words]
                ];
        }
    }
}

sub init {
    my ($self) = @_;
    $self->clear_fields();
    $self->clear_score();
    $self->exercise([]);
    $self->pos($self->min);

    $self->load_exercise_ids();
    $self->fetch_exercises(0, $self->max - 1);

    $self->load_step($self->pos);
}

sub clear_fields {
    my ($self) = @_;
    $self->input->Clear();
    $self->text->SetLabel('');
    $self->Layout();
}

sub load_fields {
    my ($self, %args) = @_;
    $self->text->SetLabel($args{text});
    $self->input->SetValue($args{input}) if $args{input};
    $self->input->SetFocus();
    $self->Layout();
}

sub set_position {
    my ($self, $pos) = @_;
    $self->position->SetLabel($pos . '/');
}

sub get_step {
    my ($self, $id) = @_;
    return $self->exercise->[$id - 1]
        if defined $self->exercise->[$id - 1];
}

sub load_step {
    my ($self, $id) = @_;
    my $step = $self->get_step($id);
    $self->load_fields(
        text  => $step->[1],
        input => $step->[2],
    );
}

# next step
sub next_step {
    my ($self) = @_;
    $self->exercise->[$self->pos - 1][2] = $self->input->GetValue
        unless defined $self->exercise->[$self->pos - 1][2];
    if ($self->pos >= $self->max) {
        my @res;
        for my $i (0 .. $self->max - 1) {
            next unless $self->exercise->[$i];
            my $e_item = $self->exercise->[$i];
            my $compare_res
                = $self->compare_strings($e_item->[2], $e_item->[3]);
            push @res,
                {
                word_id => $e_item->[0],
                word    => $e_item->[1],
                note    => $compare_res->[2],
                user    => [[$compare_res->[1], $compare_res->[0]]],
                score   => $compare_res->[0],
                other   => [map { $_->[1] } splice(@$compare_res, 3)]
                };
        }
        if ($self->result->fill_result(@res)->ShowModal() == wxID_OK) {

            # store results in a DB tables
            $main::ioc->lookup('db')->schema->resultset('TestSession')
                ->add(TEST_ID, sum(map { $_->{score} } @res), \@res);
        }
        $self->result->Destroy();
        $self->clear_result();
        $self->reset_session();
        return;
    }
    $self->clear_fields;
    $self->pos($self->pos + 1);
    $self->load_step($self->pos);
}

# one step back
sub prev_step {
    my ($self) = @_;
    return unless $self->pos > $self->min;
    $self->clear_fields;
    $self->pos($self->pos - 1);
    $self->load_step($self->pos);
    $self->SetFocus();
}

sub reset_session {
    my ($self) = @_;
    $self->init();
}

sub strip_string {
    my ($string) = @_;
    $string =~ s/[(][^)]+[)]//g;    # remove all characters between parentheses
    $string =~ s/\W/ /g;
    $string =~ s/_/ /g;
    $string =~ s/[ ]{2,}/ /g;
    $string =~ s/\s+$//;
    $string =~ s/^\s+//;
    lc $string;
}

sub compare_strings {
    my ($self, $got, $expected) = @_;

    my @e;
    if (length $got > 0) {
        for my $expected_item (@{$expected}) {
            unless ($expected_item->[1]) {
                push @e, [0, $got, ''];
                last;
            }
            my $string = $expected_item->[1];

            # first attempt
            if ($got eq $string) {
                push @e, [100, $got, $string];
                last;
            }
            my $got_stripped    = strip_string($got);
            my $string_stripped = strip_string($string);

            # second attempt
            if ($got_stripped eq $string_stripped) {
                push @e, [100, $got, $string];
                last;
            }

            # diff
            my @a = String::Diff::diff_merge($got_stripped, $string_stripped);
            my $plus = (reduce { $a + $b }
                map { length $_ } ($a[0] =~ /\[([^\]]+)\]/g)) // 0;
            my $minus = (reduce { $a + $b }
                map { length $_ } ($a[0] =~ /[{]([^}]+)[}]/g)) // 0;
            my $total_perc = 100 - (
                  $plus > $minus
                ? $plus / length($got_stripped)
                : $minus / length($string_stripped)
            ) * 100;

            push @e, [$total_perc, $got, $string];
        }
    }
    else {
        push @e, [0, $got, $expected->[0][1] // ''];
    }
    my $matched_most
        = (@e == 1 ? $e[0] : reduce { $a->[0] > $b->[0] ? $a : $b } @e);
    push @{$matched_most},
        grep { $matched_most->[2] ne $_->[1] } @{$expected};
    $matched_most;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
