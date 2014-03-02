package Dict::Learn::Main::Result::Words;
use base 'DBIx::Class::Core';

=head1 NAME

Dict::Learn::Main::Result::Words

=head1 DESCRIPTION

TODO add description

=cut

__PACKAGE__->table('word_xref');
__PACKAGE__->add_columns(
    qw( word1_id word2_id dictionary_id partofspeech_id rel_type category_id
        note cdate mdate )
);
__PACKAGE__->set_primary_key(qw( word1_id word2_id rel_type ));
__PACKAGE__->has_one(
    dictionary => 'Dict::Learn::Main::Result::Dictionary',
    {'foreign.dictionary_id' => 'self.dictionary_id'},
    {   cascade_update => 0,
        cascade_delete => 0
    }
);
__PACKAGE__->belongs_to(
    word1_id => 'Dict::Learn::Main::Result::Word',
    {'foreign.word_id' => 'self.word1_id'},
    {   cascade_delete => 0,
        cascade_update => 0
    }
);
__PACKAGE__->belongs_to(
    word2_id => 'Dict::Learn::Main::Result::Word',
    {'foreign.word_id' => 'self.word2_id'},
    {   cascade_delete => 0,
        cascade_update => 0
    }
);
__PACKAGE__->has_one(
    partofspeech => 'Dict::Learn::Main::Result::PartOfSpeech',
    {'foreign.partofspeech_id' => 'self.partofspeech_id'},
    {   cascade_delete => 0,
        cascade_update => 0
    }
);
__PACKAGE__->has_one(
    rel_type => 'Dict::Learn::Main::Result::RelType',
    {'foreign.rel_type' => 'self.rel_type'},
    {
        cascade_delete => 0,
        cascade_update => 0
    }
);

1;
