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

sub fields : Tests {
    my ($self) = @_;

    my $item_id = 1;
    
    $self->test_field(
        name => 'item_id',
        type => 'Int',
    );
    $self->test_field(
        name => 'enable',
        type => 'Bool',
    );
    $self->test_field(
        name => 'edit_origin',
        type => 'HashRef',
    );
    $self->test_field(
        name => 'parent',
        is   => 'ro',
        type => 'Dict::Learn::Frame',
    );
    $self->test_field(
        name => 'cb_irregular',
        is   => 'ro',
        type => 'Wx::CheckBox',
    );
    $self->test_field(
        name => 'translations',
        is   => 'ro',
        type => 'Dict::Learn::Frame::AddWord::Translations',
    );
    for my $field (qw(word_note word_src word2_src word3_src)) {
        $self->test_field(
            name => $field,
            is   => 'ro',
            type => 'Wx::TextCtrl',
        );
    }
    for my $field (qw(vbox_src hbox_btn hbox_words vbox)) {
        $self->test_field(
            name => $field,
            is   => 'ro',
            type => 'Wx::BoxSizer',
        );
    }
    for my $field (qw(btn_add_word btn_translate btn_clear btn_cancel)) {
        $self->test_field(
            name => $field,
            is   => 'ro',
            type => 'Wx::Button',
        );
    }
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

    subtest 'Check for duplicates of the words' => sub {
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
    };

    my %item_with_word_id = (
        %item,
        word    => undef,
        word_id => 1
    );

    subtest 'Check for duplicates of the word_id' => sub {
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
    };
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
