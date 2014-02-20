package Test::Dict::Learn::Frame::PrepositionTest;

use parent 'Test::Dict::Learn::Frame::Base';
use common::sense;

use Const::Fast;
use Test::More;
use Wx qw[:everything];

use lib::abs qw( ../../../../../../lib );

use Dict::Learn::Frame::PrepositionTest;
use Data::Printer;

const my $PREPOSITION => 5;

sub startup : Test(startup => no_plan) {
    my ($self) = @_;

    my $parent = bless {} => 'Dict::Learn::Frame';

    # `Wx::Panel` wants parent frame to be real
    my $frame = Wx::Frame->new(undef, wxID_ANY, 'Test');

    $self->SUPER::startup();
    $self->_populate_db();

    $self->{frame}
        = Dict::Learn::Frame::PrepositionTest->new($parent, $frame, wxID_ANY,
        wxDefaultPosition, wxDefaultSize, wxTAB_TRAVERSAL);

    ok($self->{frame}, qw{PrepositionTest page created});
}

sub fields : Tests {
    my ($self) = @_;

    for (
        [qw(parent)                                 => 'Dict::Learn::Frame'],
        [qw(min)                                    => 'Int'],
        [qw(preps)                                  => 'ArrayRef'],
        [qw(spin)                                   => 'Wx::SpinCtrl'],
        [qw(position translations)                  => 'Wx::StaticText'],
        [qw(hbox hbox_exercise hbox_position vbox)  => 'Wx::BoxSizer'],
        [qw(btn_prev btn_next btn_reset btn_giveup) => 'Wx::Button'],
        )
    {
        my $type = pop @$_;
        $self->test_field(name => $_, type => $type, is => 'ro') for @$_;
    }

    for (
        [qw(pos max)     => 'Int'],
        [qw(total_score) => 'Num'],
        [qw(exercise)    => 'ArrayRef'],
        )
    {
        my $type = pop @$_;
        $self->test_field(name => $_, type => $type, is => 'rw') for @$_;
    }
}

sub _populate_db {
    my ($self) = @_;

    my $test_category_id
        = $Dict::Learn::Frame::PrepositionTest::TEST_CATEGORY_ID;

    Database->schema->resultset('TestCategory')->create(
        {
            test_category_id => $test_category_id,
            test_id          => $Dict::Learn::Frame::PrepositionTest::TEST_ID,
            dictionary_id    => Dict::Learn::Dictionary->curr_id,
            name             => 'Preposition Test',
        },
    );

    for (
        # Prepositions
        [in    => qw(в)],
        [on    => qw(на)],
        [at    => qw(на в о об)],
        [under => qw(під)],
        [to    => qw(до)],
        [with  => qw(з)],
        [from  => qw(з)],

        # Expressions
        ['result in'  => q(призвести до)],
        ['agree with' => q(погоджуватись з)],
        ['agree on'   => q(погоджуватись на)],
        ['in one'     => q(одразу)],
        ['in person'  => q(особисто)],
        ['in vain'    => q(дарма)],
        ['at least'   => q(принаймні)],
        ['at latest'  => q(найпізніше)],
        ['in return'  => q(у відповідь)],
        ['on purpose' => q(навмисно)],
        )
    {
        my ($word, @translations) = @$_;

        $self->_new_word_in_db(
            word         => $word,
            translations => [
                map { { word => $_, partofspeech_id => $PREPOSITION } }
                    @translations
            ],
            test_category => $test_category_id,
        );
    }
}

sub reset_attributes : Tests {
    my ($self) = @_;

    my $frame = $self->{frame};

    # At first, set random data
    $frame->pos(3);
    $frame->exercise([1..9]);
    $frame->total_score(9);

    # and reset them
    $frame->_reset_attributes();

    # and finally make sure all these attributes were reset
    is($frame->pos => 0, 'Position is 0');
    is(scalar(@{$frame->exercise}) => 0, 'Exercise is empty');
    is($frame->total_score => 0, 'Total score is 0');
}

sub extract_prepositions : Tests {
    my ($self) = @_;

    my $frame = $self->{frame};

    subtest qq{Extract prepositions from a sentence} => sub {
        for (
            ['result in'             => qw(in)],
            ['agree with'            => qw(with)],
            ['agree on'              => qw(on)],
            ['in one'                => qw(in)],
            ['in person'             => qw(in)],
            ['in vain'               => qw(in)],
            ['at least'              => qw(at)],
            ['at latest'             => qw(at)],
            ['in return'             => qw(in)],
            ['on purpose'            => qw(on)],
            ['from Monday to Friday' => qw(from to)],
            )
        {
            my ($phrase, @prepositions) = @$_;
            is_deeply(
                $frame->_extract_prepositions($phrase) => \@prepositions,
                "\"$phrase\": \"" . join('", "', @prepositions)."\""
            );
        }
    };
}

sub split_into_chunks : Tests {
    my ($self) = @_;

    my $frame = $self->{frame};

    subtest qq{Split the sentences into chunks} => sub {
        for (
            ['agree with you'          => 'agree', 'you'],
            ['agree on this'           => 'agree', 'this'],
            ['do it in one'            => 'do it', 'one'],
            ['know him in person'      => 'know him', 'person'],
            ['did it in vain'          => 'did it', 'vain'],
            ['at least 10 people'      => '', 'least 10 people'],
            ['from Monday to Friday'   => '', 'Monday', 'Friday'],
            ["I's what I'm working on" => "I's what I'm working"],
            )
        {
            my ($clause, @chunks) = @$_;
            my $used_preps = $frame->_extract_prepositions($clause);
            is_deeply(
                $frame->_split_into_chunks($clause, $used_preps) => \@chunks,
                "\"$clause\": \"".join('", "', @chunks)."\""
            );
        }
    };
}

sub render_position : Tests {
    my ($self) = @_;

    my $frame = $self->{frame};

    subtest qq{Position label} => sub {
        for my $position (0 .. 100) {
            $frame->pos($position);
            $frame->_render_position();
            my $position_label = sprintf '%00d/', $position + 1;
            is(
                $frame->position->GetLabel => $position_label,
                qq{Position label is '$position_label'}
            );
        }
    };

}

1;
