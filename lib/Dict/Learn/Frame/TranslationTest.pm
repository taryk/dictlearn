package Dict::Learn::Frame::TranslationTest 0.1;

use Wx qw[:everything];
use Wx::Event qw[:everything];

use Data::Printer;

use Moose;
use MooseX::NonMoose;
extends 'Wx::Panel';

use Carp qw[ croak confess ];
use DateTime;
use List::Util qw[ shuffle reduce sum ];
use String::Diff qw[ diff_fully diff diff_merge ];

use common::sense;
# use warnings FATAL => "all";

use Database;
use Dict::Learn::Dictionary;
use Dict::Learn::Frame::TranslationTest::Result;

sub TEST_ID { 1 }

=item min

=cut

has min   => (is => 'ro', default => 1);

=item max

=cut

has max => (
    is      => 'rw',
    default => 3,
    trigger => sub {
        my ($self, $new_index, $prev_index) = @_;

        my $spin_value = $self->spin->GetValue;
        $self->spin->SetValue($new_index) if $new_index != int $spin_value;
        say "setting max value $new_index";
        unless (defined $self->exercise->[$new_index]) {
            my $last_index = $#{ $self->exercise } + 1;
            say "last index - $last_index";
            return unless $new_index >= $last_index;
            $self->fetch_exercises($last_index, $new_index);
        }
    },
);

=item total_score

=cut

has total_score => (
    is      => 'rw',
    default => 0,
    clearer => 'clear_score',
);

=item exercise

=cut

has exercise => (
    is      => 'rw',
    default => sub { [] },
    clearer => 'clear_exercise',
);

=item parent

=cut

has parent => (
    is  => 'ro',
    isa => 'Dict::Learn::Frame',
);

=item hbox

=cut

has hbox => (
    is      => 'ro',
    isa     => 'Wx::BoxSizer',
    default => sub { Wx::BoxSizer->new(wxHORIZONTAL) },
);

=item hbox_position

=cut

has hbox_position => (
    is      => 'ro',
    isa     => 'Wx::BoxSizer',
    default => sub { Wx::BoxSizer->new(wxHORIZONTAL) },
);

=item vbox

=cut

has vbox => (
    is      => 'ro',
    isa     => 'Wx::BoxSizer',
    default => sub { Wx::BoxSizer->new(wxVERTICAL) },
);

=item pos

=cut

has pos => (
    is      => 'rw',
    isa     => 'Int',
    default => sub { shift->min },
    trigger => sub {
        my ($self, $pos) = @_;

        $self->set_position($pos);
    },
);

=item position

=cut

has position => (
    is      => 'ro',
    isa     => 'Wx::StaticText',
    default => sub {
        my $self = shift;

        Wx::StaticText->new($self, wxID_ANY, $self->min . '/',
            wxDefaultPosition, wxDefaultSize, wxALIGN_CENTRE);
    },
);

=item spin

=cut

has spin => (
    is      => 'ro',
    isa     => 'Wx::SpinCtrl',
    default => sub {
        Wx::SpinCtrl->new(shift, wxID_ANY, 0, wxDefaultPosition,
            wxDefaultSize, wxSP_ARROW_KEYS | wxSP_WRAP);
    },
);

=item

=cut

has test_category => (
    is => 'ro',
    isa => 'Wx::ComboBox',
    lazy_build => 1,
);

sub _build_test_category {
    my $self = shift;

    my $combobox = Wx::ComboBox->new($self, wxID_ANY, '', wxDefaultPosition,
        wxDefaultSize, [], 0, wxDefaultValidator);

    $combobox->Clear();
    for my $category (@{ $self->predefined_categories }) {
        my $id = $category->[1][0];
        $combobox->Append($category->[0], $id);
    }
    $combobox->SetSelection(0);
    
    Dict::Learn::Dictionary->cb(
        sub {
            my $dict = shift;
            my $test_categories_rs
                = Database->schema->resultset('TestCategory')
                ->search({dictionary_id => $dict->curr_id});
            for ($test_categories_rs->all()) {
                $combobox->Append($_->name, $_->test_category_id);
            }
        }
    );
    
    return $combobox;
}

=item text

=cut

has text => (
    is      => 'ro',
    isa     => 'Wx::StaticText',
    default => sub {
        Wx::StaticText->new(shift, wxID_ANY, '', wxDefaultPosition,
            wxDefaultSize, wxALIGN_CENTRE);
    },
);

=item input

=cut

has input => (
    is      => 'ro',
    isa     => 'Wx::TextCtrl',
    default => sub {
        Wx::TextCtrl->new(shift, wxID_ANY, '', wxDefaultPosition,
            wxDefaultSize, wxTE_LEFT);
    },
);

=item btn_prev

=cut

has btn_prev => (
    is      => 'ro',
    isa     => 'Wx::Button',
    default => sub {
        Wx::Button->new(shift, wxID_ANY, 'Prev', wxDefaultPosition,
            wxDefaultSize);
    },
);

=item btn_next

=cut

has btn_next => (
    is      => 'ro',
    isa     => 'Wx::Button',
    default => sub {
        Wx::Button->new(shift, wxID_ANY, 'Next', wxDefaultPosition,
            wxDefaultSize);
    },
);

=item btn_reset

=cut

has btn_reset => (
    is      => 'ro',
    isa     => 'Wx::Button',
    default => sub {
        Wx::Button->new(shift, wxID_ANY, 'Reset', wxDefaultPosition,
            wxDefaultSize);
    },
);

=item btn_show_translation

=cut

has btn_show_translation => (
    is      => 'ro',
    isa     => 'Wx::Button',
    default => sub {
        Wx::Button->new(shift, wxID_ANY, 'Show translation', wxDefaultPosition,
            wxDefaultSize);
    },
);

=item translation

=cut

has translation => (
    is      => 'ro',
    isa     => 'Wx::StaticText',
    default => sub {
        Wx::StaticText->new(shift, wxID_ANY, '', wxDefaultPosition,
            wxDefaultSize, wxALIGN_LEFT);
    },
);


=item result

=cut

has result => (
    is      => 'ro',
    isa     => 'Dict::Learn::Frame::TranslationTest::Result',
    lazy    => 1,
    clearer => 'clear_result',
    default => sub {
        Dict::Learn::Frame::TranslationTest::Result->new(
            shift, wxID_ANY, 'Result', wxDefaultPosition,
            [800, 600],
            wxDEFAULT_DIALOG_STYLE | wxRESIZE_BORDER | wxSTAY_ON_TOP
        )
    }
);

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

    $self->hbox->Add($self->btn_prev,             0, wxALL | wxGROW,  0);
    $self->hbox->Add($self->btn_next,             0, wxALL | wxGROW,  0);
    $self->hbox->Add($self->btn_reset,            0, wxLEFT | wxGROW, 40);
    $self->hbox->Add($self->btn_show_translation, 0, wxLEFT | wxGROW, 40);

    $self->hbox_position->Add($self->position, 0, wxGROW, 0);
    $self->hbox_position->Add($self->spin,     0, wxGROW, 0);
    $self->hbox_position->Add($self->test_category, 0, wxGROW, 0);
    
    $self->spin->SetRange(2, 100);
    $self->spin->SetValue(3);

    $self->vbox->Add($self->hbox_position, 0, wxTOP | wxGROW,          5);
    $self->vbox->Add($self->text,          0, wxTOP | wxGROW,          20);
    $self->vbox->Add($self->input,         0, wxTOP | wxGROW,          5);
    $self->vbox->Add($self->hbox,          0, wxTOP | wxGROW,          20);
    $self->vbox->Add($self->translation,   0, wxTOP | wxLEFT | wxGROW, 20);

    $self->SetSizer($self->vbox);
    $self->Layout();
    $self->vbox->Fit($self);

    # events
    EVT_COMBOBOX($self, $self->test_category, \&reset_session);
    
    EVT_BUTTON($self, $self->btn_prev,             \&prev_step);
    EVT_BUTTON($self, $self->btn_next,             \&next_step);
    EVT_BUTTON($self, $self->btn_reset,            \&reset_session);
    EVT_BUTTON($self, $self->btn_show_translation, \&show_translation);

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

sub predefined_categories {
    my $dtf = Database->schema->storage->datetime_parser;
    [
        ['Recent 10'  => [-1, {}, { rows => 10,  page => 1 }]],
        ['Recent 50'  => [-2, {}, { rows => 50,  page => 1 }]],
        ['Recent 100' => [-3, {}, { rows => 100, page => 1 }]],
        [
            "Today's" => [
                -4,
                {
                    'me.cdate' => {
                        -between => [
                            $dtf->format_datetime(DateTime->today),
                            $dtf->format_datetime(DateTime->now),
                        ]
                    }
                }
            ]
        ],
        [
            "Yesterday's" => [
                -5,
                {
                    'me.cdate' => {
                        -between => [
                            $dtf->format_datetime(
                                DateTime->now->subtract(days => 1)
                                    ->truncate(to => 'day')
                            ),
                            $dtf->format_datetime(DateTime->today),
                        ],
                    },
                },
                {},
            ],
        ],
        [
            "This week" => [
                -6,
                {
                    'me.cdate' => {
                        -between => [
                            $dtf->format_datetime(
                                DateTime->now->subtract(days => 7)
                                    ->truncate(to => 'day')
                            ),
                            $dtf->format_datetime(DateTime->now),
                        ],
                    },
                },
                {},
            ]
        ],
        [
            "Tested within last 12 hours" => [
                -7,
                {
                    'last_test.cdate' => {
                        -between => [
                            $dtf->format_datetime(
                                DateTime->now->subtract(hours => 12)
                            ),
                            $dtf->format_datetime(DateTime->now),
                        ]
                    }
                },
                {
                    join     => ['last_test'],
                    group_by => ['me.word_id']
                }
            ],
        ],
        [
            "Tested within last 24 hours" => [
                -8,
                {
                    'last_test.cdate' => {
                        -between => [
                            $dtf->format_datetime(
                                DateTime->now->subtract(hours => 24)
                            ),
                            $dtf->format_datetime(DateTime->now),
                        ]
                    }
                },
                {
                    join => ['last_test'],
                    group_by => ['me.word_id'],
                },
            ],
        ],
        [
            "Tested more than 12 hours ago" => [
                -9,
                {
                    'last_test.cdate' => {
                        ">" => $dtf->format_datetime(
                            DateTime->now->subtract(hours => 24)
                        ),
                    }
                },
                {
                    join => ['last_test'],
                    group_by => ['me.word_id']
                },
            ]
        ],
        [
            "Tested more than 24 hours ago" => [
                -10,
                {
                    'last_test.cdate' => {
                        ">" => $dtf->format_datetime(
                            DateTime->now->subtract(hours => 24)
                        ),
                    }
                },
                {
                    join => ['last_test'],
                    group_by => ['me.word_id']
                },
            ],
        ],
        ['All' => [-11, {}, {}]],
    ];
}

{
    my @ids;

    sub set_ids { @ids = @_ }
    
    sub load_exercise_ids {
        my ($self) = @_;

        my $curr_category = $self->test_category->GetClientData(
            $self->test_category->GetSelection());

        if ($curr_category > 0) {
            my $id_rs = Database->schema->resultset('TestCategoryWords')
            ->search(
            {
                test_category_id => $curr_category,
            },
            {
                join     => 'word_id',
                order_by => { -desc => 'test_category_id' },
            }
            );
            @ids = shuffle map { $_->word_id->word_id } ($id_rs->all());
        } else {
            my ($category_settings) = grep {
                $_->[1][0] == $curr_category
            } @{ $self->predefined_categories };

            # let's get all ids
            my $id_rs
                = Database->schema->resultset('Word')->search(
                {
                    'me.in_test' => 1,
                    'me.lang_id' =>
                        Dict::Learn::Dictionary->curr->{language_orig_id}
                        {language_id},
                    'rel_words.word2_id' => {'!=' => undef},
                    %{ $category_settings->[1][1] || {} },
                },
                {
                    select   => ['me.word_id'],
                    join     => ['rel_words'],
                    order_by => { -desc => 'me.word_id' },
                    distinct => 1,
                    %{ $category_settings->[1][2] || {} },
                }
                );
            # $id_rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
            @ids = shuffle map { $_->word_id } ($id_rs->all());
        }
        my $count = scalar(@ids);
        say "Fetched $count words. [".join(' ', @ids)."]";
        $self->max($count) if $count < $self->max;
    }

    sub fetch_exercises {
        my ($self, $from, $to) = @_;

        say "fetching exercises from $from to $to";
        my $words
            = Database->schema->resultset('Word')
            ->search({'me.word_id' => {in => [@ids[$from .. $to]]}},
            {distinct => 1});
        while (my $word = $words->next) {
            push @{$self->exercise},
                [
                    $word->word_id, $word->word, undef,
                    [map { [$_->word_id, $_->word] } $word->words]
                ];
        }
        $self->check_exercise_consistency();
    }

    sub check_exercise_consistency {
        my ($self) = @_;
        for ( 0 .. $self->max-1 ) {
            my $item = $self->exercise->[$_];
            next if defined $item && ref $item eq 'ARRAY';
            p($self->exercise);
            confess "${_}th of ".($self->max-1)." element is wrong";
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
    $self->translation->SetLabel('');
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
            Database->schema->resultset('TestSession')
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

sub show_translation {
    my ($self) = @_;

    $self->translation->SetLabel(
        join "\n", map { "* $_->[1]" } @{ $self->exercise->[$self->pos - 1][3] }
    );
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
