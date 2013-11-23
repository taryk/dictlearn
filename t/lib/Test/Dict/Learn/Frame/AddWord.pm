package Test::Dict::Learn::Frame::AddWord;

use parent 'Test::Class';
use common::sense;

use Data::Printer;
use Test::More;
use Wx qw[:everything];

use lib::abs qw( ../../../../../../lib );

use Dict::Learn::Frame::AddWord;

sub startup : Test(startup => no_plan) {
    my ($self) = @_;

    my $parent = bless {} => 'Dict::Learn::Frame';
    my $frame  = Wx::Frame->new(undef, wxID_ANY, 'Test');
    $self->{frame}
        = Dict::Learn::Frame::AddWord->new($parent, $frame, wxID_ANY,
        wxDefaultPosition, wxDefaultSize, wxTAB_TRAVERSAL);

}

sub check_for_duplicates : Tests {
    my ($self) = @_;

    my @items = (
        {
            lang_id      => 1,
            note         => '',
            partofspeech => 0,
            word         => 'test1',
            word_id      => undef,
        },
        {
            lang_id      => 1,
            note         => '',
            partofspeech => 0,
            word         => 'test2',
            word_id      => undef,
        }
    );

    ok(
        !$self->{frame}->check_for_duplicates(\@items),
        q{There's no duplicates in a single item}
    );
    is_deeply(
        $self->{frame}->check_for_duplicates([$items[0], $items[0]]), $items[0],
        q{Duplication was found}
    );

}

1;
