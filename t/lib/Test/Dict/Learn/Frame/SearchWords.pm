package Test::Dict::Learn::Frame::SearchWords;

use parent 'Test::Class';
use common::sense;

use Data::Printer;
use Test::MockObject;
use Test::More;
use Wx qw[:everything];

use lib::abs qw( ../../../../../../lib );

use Container;
use Database;
use Dict::Learn::Dictionary;
use Dict::Learn::Frame;
use Dict::Learn::Frame::SearchWords;

sub startup : Test(startup => no_plan) {
    my ($self) = @_;

    # Use in-memory DB for this test
    Container->params( dbfile => ':memory:', debug  => 1 );
    Container->lookup('db')->install_schema();

    # Set default dictionary
    Dict::Learn::Dictionary->all();
    Dict::Learn::Dictionary->set(0);

    my $parent = Dict::Learn::Frame->new(undef, wxID_ANY, 'DictLearn Test',
        wxDefaultPosition, wxDefaultSize,
        wxDEFAULT_DIALOG_STYLE | wxRESIZE_BORDER);

    # `Wx::Panel` wants parent frame to be real
    my $frame  = Wx::Frame->new(undef, wxID_ANY, 'Test');
    $self->{frame}
        = Dict::Learn::Frame::SearchWords->new($parent, $frame, wxID_ANY,
        wxDefaultPosition, wxDefaultSize, wxTAB_TRAVERSAL);
    ok($self->{frame}, qw{SearchWords page created});
}

sub fields : Tests {
    my ($self) = @_;

    pass;
}

1;
