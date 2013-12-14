package Dict::Learn::Main::Result::TestCategoryWords 0.1;
use base qw[ DBIx::Class::Core ];

=head1 NAME

Dict::Learn::Main::ResultSet::TestCategoryWords

=head1 DESCRIPTION

TODO add description

=cut

__PACKAGE__->table('test_category_word_xref');
__PACKAGE__->add_columns(
    qw[ test_category_id word_id partofspeech_id cdate mdate ]
);
__PACKAGE__->set_primary_key(qw[ test_category_id word_id partofspeech_id ]);
__PACKAGE__->belongs_to(
    test_category_id => 'Dict::Learn::Main::Result::TestCategory',
    'test_category_id',
    {   cascade_delete => 0,
        cascade_update => 0
    }
);
__PACKAGE__->belongs_to(
    word_id => 'Dict::Learn::Main::Result::Word',
    'word_id',
    {   cascade_delete => 0,
        cascade_update => 0
    }
);
__PACKAGE__->belongs_to(
    partofspeech_id => 'Dict::Learn::Main::Result::PartOfSpeech',
    'partofspeech_id',
    {   cascade_delete => 0,
        cascade_update => 0
    }
);

1;
