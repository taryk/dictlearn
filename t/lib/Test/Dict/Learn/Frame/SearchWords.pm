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

    my $parent = bless {} => 'Dict::Learn::Frame';

    # `Wx::Panel` wants parent frame to be real
    my $frame = Wx::Frame->new(undef, wxID_ANY, 'Test');

    $self->{frame}
        = Dict::Learn::Frame::SearchWords->new($parent, $frame, wxID_ANY,
        wxDefaultPosition, wxDefaultSize, wxTAB_TRAVERSAL);

    *Dict::Learn::Frame::SearchWords::set_status_text = sub { };

    # Set a default dictionary
    Dict::Learn::Dictionary->all();
    Dict::Learn::Dictionary->set(0);

    ok($self->{frame}, qw{SearchWords page created});
}

sub shutdown : Test(shutdown) {
    my ($self) = @_;

    Dict::Learn::Dictionary->clear();
}

sub fields : Tests {
    my ($self) = @_;

    for (
        [qw(parent)                  => 'Dict::Learn::Frame'],
        [qw(combobox cb_add_to_test) => 'Wx::ComboBox'],
        [qw(sidebar)                 => 'Dict::Learn::Frame::Sidebar'],
        [qw(st_add_to_test)          => 'Wx::StaticText'],
        [qw(lb_words lb_examples)    => 'Wx::ListCtrl'],
        [
            qw(
                  lookup_hbox vbox_btn_words hbox_words
                  vbox_btn_examples hbox_examples
                  hbox_add_to_test
                  vbox hbox
             ) => 'Wx::BoxSizer'
        ],
        [
            qw(
                  btn_lookup btn_reset btn_addword
                  btn_edit_word btn_unlink_word btn_delete_word
                  btn_add_example btn_edit_example btn_unlink_example
                  btn_delete_example btn_add_to_test
             ) => 'Wx::Button'
        ],
        )
    {
        my $type = pop @$_;
        $self->test_field(name => $_, type => $type, is => 'ro') for @$_;
    }

}

sub test_field {
    my ($self, %params) = @_;

    my $field = delete $params{name};
    $params{is} //= 'rw';

    my $value;
    if ($params{is} eq 'rw') {
        given ($params{type}) {
            when ('Bool')     { $value = 1 }
            when ('Int')      { $value = 3 }
            when ('ArrayRef') { $value = [1 .. 9] }
            when ('HashRef')  { $value = { key => 'value' } }
            when (['Str', undef]) { $value = 'test' }
            default { $value = bless {} => $params{type} }
        }
    }
    subtest $field => sub {
        ok($self->{frame}->$field($value), qq{We can set '$field'})
            if $params{is} eq 'rw';
        my $attr = $self->{frame}->meta->get_attribute($field);
        if ($params{type}) {
            ok($attr->has_type_constraint, qq{$field has a type constraint});
            is($attr->type_constraint, $params{type}, qq{It's $params{type}});
        }
        ok(defined $self->{frame}->$field, q{We can get a value})
            if $params{is} eq 'rw'
            || $attr->has_default
            || $attr->has_builder;
    };
}

1;
