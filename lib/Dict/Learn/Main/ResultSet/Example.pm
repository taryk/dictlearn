package Dict::Learn::Main::ResultSet::Example;
use base 'DBIx::Class::ResultSet';

use namespace::autoclean;
use common::sense;

use Data::Printer;

=head1 NAME

Dict::Learn::Main::ResultSet::Example

=head1 DESCRIPTION

TODO add description

=head1 METHODS

=head2 export_data

TODO add description

=cut

sub export_data {
    my ($self) = @_;
    my $rs = $self->search({}, {});
    $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
    $rs->all();
}

=head2 import_data

TODO add description

=cut

sub import_data {
    my ($self, $data) = @_;
    $self->populate($data);
    return 1;
}

=head2 clear_data

TODO add description

=cut

sub clear_data {
    my ($self) = @_;
    $self->delete_all();
}

=head2 add_one

TODO add description

=cut

sub add_one {
    my $self        = shift;
    my %params      = @_;
    my %new_example = (
        example => $params{text},
        note    => $params{note},
        lang_id => $params{lang_id},
    );
    $new_example{in_test} = $params{in_test} if defined $params{in_test};
    my $new_example = $self->create(\%new_example);
    if ($params{word}) {
        my $rs
            = $self->result_source->schema->resultset('WordExample')->create(
            {   word_id    => $params{word}[0],
                example_id => $new_example->example_id,
            }
            );
    }
    for (@{$params{translate}}) {
        if (defined $_->{example_id}) {
            $new_example->add_to_examples({example_id => $_->{example_id}},
                {dictionary_id => $params{dictionary_id}});
        }
        else {
            next unless defined $_->{text};
            $new_example->add_to_examples(
                {   example => $_->{text},
                    lang_id => $_->{lang_id},
                },
                {dictionary_id => $params{dictionary_id}}
            );
        }
    }

    return $self;
}

=head2 update_one

TODO add description

=cut

sub update_one {
    my $self   = shift;
    my %params = @_;
    my %update;
    $update{example} = $params{text}    if defined $params{text};
    $update{note}    = $params{note}    if defined $params{note};
    $update{lang_id} = $params{lang_id} if defined $params{lang_id};
    $update{idioma}  = $params{idioma}  if defined $params{idioma};
    $update{in_test} = $params{in_test} if defined $params{in_test};
    my $updated_example = $self->search({example_id => $params{example_id}})
        ->first->update(\%update);

    for (@{$params{translate}}) {

        # create new
        unless (defined $_->{example_id}) {
            next unless defined $_->{text};
            my %update_tr = (example => $_->{text});
            $update_tr{note}    = $_->{note}    if defined $_->{note};
            $update_tr{lang_id} = $_->{lang_id} if defined $_->{lang_id};
            $update_tr{idioma}  = $_->{idioma}  if defined $_->{idioma};
            $updated_example->add_to_examples(\%update_tr,
                {dictionary_id => $params{dictionary_id},});
            next;
        }

        # update or delete existed
        my $example_xref
            = $self->result_source->schema->resultset('Examples')
            ->find_or_create(
            {   example1_id => $params{example_id},
                example2_id => $_->{example_id},
            }
            );
        if (defined $_->{text}) {
            next if $_->{text} == 0;
            $example_xref->example2_id->update(
                {   example => $_->{text},
                    note    => $_->{note},
                    lang_id => $_->{lang_id},
                    idioma  => $_->{idioma} || 0,
                }
            );
        }
        else {
            $example_xref->delete;
        }
    }

    return $self;
}

=head2 delete_one

TODO add description

=cut

sub delete_one {
    my $self = shift;
    $self->search({example_id => [@_]})->delete;
}

=head2 unlink_one

TODO add description

=cut

sub unlink_one {
    my $self = shift;
    $self->search({example1_id => [@_]})->delete;
}

=head2 select_one

TODO add description

=cut

sub select_one {
    my $self       = shift;
    my $example_id = shift;
    my $rs         = $self->search({'me.example_id' => $example_id,},
        {prefetch => {'rel_examples' => ['example2_id']},});
    $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
    $rs->first();
}


=head2 select

TODO add description

=cut

sub select {
    my $self   = shift;
    my %params = @_;
    my $rs     = $self->search(
        {   -and => [
                'word_id.word_id' => $params{word_id},
                -or               => [
                    'rel_examples.dictionary_id' => $params{dictionary_id},
                    'rel_examples.dictionary_id' => undef
                ],
            ],
        },
        {   select => [
                qw| me.example_id
                    me.example
                    example2_id.example
                    rel_examples.note
                    me.cdate
                    me.mdate
                    me.in_test
                    |
            ],
            as => [
                qw| example_id
                    example_orig
                    example_tr
                    note
                    cdate
                    mdate
                    in_test
                    |
            ],
            join => {rel_examples => ['example2_id'], words => ['word_id']},
            order_by => {-asc => 'me.example_id'}
        }
    );
    $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
    $rs->all();
}

=head2 get_all

TODO add description

=cut

sub get_all {
    my $self    = shift;
    my $lang_id = shift;
    my $rs      = $self->search({'me.lang_id' => $lang_id,});
    $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
    $rs->all();
}

=head2 select_examples_grid

TODO add description

=cut

sub select_examples_grid {
    my $self   = shift;
    my %params = @_;
    my $rs     = $self->search(
        {'me.lang_id' => $params{lang1_id}},
        {   join   => ['rel_examples', 'words'],
            select => [
                'me.example_id',
                'me.example',
                'me.in_test',
                {count => ['rel_examples.example2_id']},
                {count => ['words.word_id']},
                'me.cdate',
                'me.mdate'
            ],
            as => [
                qw|example_id example in_test rel_examples rel_words
                    cdate mdate|
            ],
            group_by => ['me.example_id'],
            order_by => {-desc => ['me.cdate']}
        }
    );
    $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
    $rs->all();
}

1;
