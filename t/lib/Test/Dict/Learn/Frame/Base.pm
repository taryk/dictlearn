package Test::Dict::Learn::Frame::Base;

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

sub startup : Test(startup => no_plan) {
    my ($self) = @_;

    # Use in-memory DB for this test
    Container->params( dbfile => ':memory:', debug  => 1 );
    Container->lookup('db')->install_schema();

    # Set default dictionary
    Dict::Learn::Dictionary->all();
    Dict::Learn::Dictionary->set(0);
}

# `z_` prefix is intended to make this method go after frame is created
sub z_after_all_startups : Test(startup) {
    my ($self) = @_;

    $self->{attributes} = {
        map { ($_->name => $_) } $self->{frame}->meta->get_all_attributes
    };
}

sub shutdown : Test(shutdown => no_plan) {
    my ($self) = @_;

    if (!$ENV{TEST_METHOD}) {
        # if there's any untested attribute, fail a test
        fail("Attribute '$_' isn't tested") for keys %{ $self->{attributes} };
    }

    Dict::Learn::Dictionary->clear();
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
        my $attr = delete $self->{attributes}{$field};
        ok($attr, qq{Attribute '$field' exists});

        ok($self->{frame}->$field($value), qq{We can set '$field'})
            if $params{is} eq 'rw';
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

sub _new_word_in_db {
    my ($self, %params) = @_;

    my $orig_lang_id
        = Dict::Learn::Dictionary->curr->{language_orig_id}{language_id};
    my $tr_lang_id
        = Dict::Learn::Dictionary->curr->{language_tr_id}{language_id};
    my $new_word = Database->schema->resultset('Word')->create(
        {
            word    => $params{word},
            lang_id => $orig_lang_id,
        }
    );

    for (@{ $params{translations} }) {
        $new_word->add_to_words(
            {
                lang_id => $tr_lang_id,
                %$_
            },
            {
                dictionary_id   => Dict::Learn::Dictionary->curr_id,
                partofspeech_id => $_->{partofspeech_id}
            }
        );
    }

    return $new_word;
}

sub _lookup_in_db {
    my ($self, %params) = @_;

    my $orig_lang_id
        = Dict::Learn::Dictionary->curr->{language_orig_id}{language_id};

    return Database->schema->resultset('Word')->search(
        {
            word    => $params{word},
            lang_id => $orig_lang_id,
        }
    )->first;
}

1;
