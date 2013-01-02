package Dict::Learn::Main::ResultSet::Example 0.1;
use base 'DBIx::Class::ResultSet';

use namespace::autoclean;

use common::sense;

use Data::Printer;

sub export_data {
  my ($self) = @_;
  my $rs = $self->search({ }, { });
  $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
  $rs->all()
}

sub import_data {
  my ($self, $data) = @_;
  $self->populate($data);
  return 1
}

sub clear_data {
  my ($self) = @_;
  $self->delete_all()
}

sub add_one {
  my $self   = shift;
  my %params = @_;
  my $new_example = $self->create({
    example => $params{text},
    note    => $params{note},
    lang_id => $params{lang_id},
  });
  if ($params{word}) {
    my $rs = $self->result_source->schema->resultset('WordExample')->create({
      word_id    => $params{word}[0],
      example_id => $new_example->example_id,
    });
  }
  for (@{ $params{translate} }) {
    if (defined $_->{example_id}) {
      $new_example->add_to_examples(
        { example_id    => $_->{example_id}     } ,
        { dictionary_id => $params{dictionary_id} }
      );
    } else {
      $new_example->add_to_examples({
        example => $_->{text},
        lang_id => $_->{lang_id},
      }, {
        dictionary_id => $params{dictionary_id}
      });
    }
  }
  $self
}

sub update_one {
  my $self = shift;
  my %params = @_;
  my %update = ( example => $params{text} );
  $update{note}    = $params{note}    if defined $params{note};
  $update{lang_id} = $params{lang_id} if defined $params{lang_id};
  $update{idioma}  = $params{idioma}  if defined $params{idioma};
  my $updated_example = $self->search(
    { example_id => $params{example_id} })->first->update(\%update);
  for ( @{ $params{translate} } ) {
    # create new
    unless (defined $_->{example_id}) {
      my %update_tr = ( example => $_->{text} );
      $update_tr{note}    = $_->{note}    if defined $_->{note};
      $update_tr{lang_id} = $_->{lang_id} if defined $_->{lang_id};
      $update_tr{idioma}  = $_->{idioma}  if defined $_->{idioma};
      $updated_example->add_to_examples(\%update_tr, {
        dictionary_id => $params{dictionary_id},
      });
      next;
    }
    # update or delete existed
    my $example_xref = $self->result_source->schema->resultset('Examples')->find_or_create({
      example1_id => $params{example_id},
      example2_id => $_->{example_id},
    });
    if (defined $_->{text}) {
      next if $_->{text} == 0;
      $example_xref->example2_id->update({
        example => $_->{text},
        note    => $_->{note},
        lang_id => $_->{lang_id},
        idioma  => $_->{idioma} || 0,
      });
    } else {
      $example_xref->delete;
    }
  }
  $self
}

sub delete_one {
  my $self = shift;
  $self->search(
    { example_id => [ @_ ] }
  )->delete;
}

sub unlink_one {
  my $self = shift;
  $self->search(
    { example1_id => [ @_ ] }
  )->delete
}

sub select_one {
  my $self       = shift;
  my $example_id = shift;
  my $rs = $self->search({
      'me.example_id'  => $example_id,
    },{
      prefetch => { 'rel_examples' => [ 'example2_id' ] },
    }
  );
  $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
  $rs->first()
}


sub select {
  my $self    = shift;
  my %params  = @_;
  my $rs   = $self->search({
    -and => [
       'word_id.word_id' => $params{word_id},
       -or => [
         'rel_examples.dictionary_id' => $params{dictionary_id},
         'rel_examples.dictionary_id' => undef
       ],
    ],
  }, {
    select => [ qw| me.example_id
                    me.example
                    example2_id.example
                    rel_examples.note
                    me.cdate
                    me.mdate
                  | ],
    as     => [ qw| example_id
                    example_orig
                    example_tr
                    note
                    cdate
                    mdate
                  | ],
    join => { rel_examples => [ 'example2_id' ], words => [ 'word_id' ] },
    order_by => { -asc => 'me.example_id' }
  });
  $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
  $rs->all()
}

sub get_all {
  my $self = shift;
  my $lang_id = shift;
  my $rs = $self->search({
     'me.lang_id' => $lang_id,
  });
  $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
  $rs->all()
}

sub select_examples_grid {
  my $self   = shift;
  my %params = @_;
  my $rs   = $self->search(
    { 'me.lang_id' => $params{lang1_id} },
    { join     => [ 'rel_examples', 'words' ],
      select   => [ 'me.example_id', 'me.example',
                  { count => [ 'rel_examples.example2_id' ] },
                  { count => [ 'words.word_id' ] },
                    'me.cdate', 'me.mdate' ],
      as       => [ qw|example_id example rel_examples rel_words
                       cdate mdate| ],
      group_by => [ 'me.example_id' ],
      order_by => { -desc => ['me.cdate'] }
    }
  );
  $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
  $rs->all()
}

1;
