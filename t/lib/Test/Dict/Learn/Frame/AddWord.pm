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

    my %item = (
        lang_id      => 1,
        note         => '',
        partofspeech => 0,
        word         => 'test',
        word_id      => undef,
    );

    my @different_words = (
        { %item, word => 'test1' },
        { %item, word => 'test2' },
    );
    ok(
        !$self->{frame}->check_for_duplicates(\@different_words),
        q{There are no duplicates in @different_words}
    );

    my @duplicate_words = (\%item, \%item);
    is_deeply(
        $self->{frame}->check_for_duplicates(\@duplicate_words), \%item,
        q{It's a duplication if two identical items passed}
    );

    my %item_with_word_id = (
        %item,
        word    => undef,
        word_id => 1
    );
    
    my @different_word_id = (
        { %item_with_word_id, word_id => 2 },
        { %item_with_word_id, word_id => 3 },
    );
    ok(
        !$self->{frame}->check_for_duplicates(\@different_word_id),
        q{There are no duplicates in @different_word_id}
    );

    my @duplicate_word_id = (\%item_with_word_id, \%item_with_word_id);
    is_deeply(
        $self->{frame}->check_for_duplicates(\@duplicate_word_id), \%item_with_word_id,
        q{It's a duplication if two identical word_id passed}
    );
}

1;
