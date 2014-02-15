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

1;
