package Dict::Learn::Widget::Sidebar;

use Wx qw[:everything];
use Wx::Event qw[:everything];
use Wx::Html;

use Moose;
use MooseX::NonMoose;
extends 'Wx::Panel';

use Carp qw[croak confess];
use Data::Printer;

use common::sense;

use Database;

=head1 NAME

Dict::Learn::Frame::Sidebar

=head1 DESCRIPTION

TODO add description

=head1 ATTRIBUTES

=head2 parent

TODO add description

=cut

has parent => (
    is  => 'ro',
    isa => 'Wx::Window',
);

=head2 word_id

ID of a word loaded here

=cut

has word_id => (
    is        => 'rw',
    isa       => 'Int',
    clearer   => 'clear_word_id',
    predicate => 'has_word_id',
);

=head2 html

TODO add description

=cut

has html => (
    is      => 'ro',
    isa     => 'Wx::HtmlWindow',
    lazy    => 1,
    default => sub {
        my $html = Wx::HtmlWindow->new(shift, wxID_ANY, wxDefaultPosition,
            wxDefaultSize);
        $html->SetPage('Dict::Learn');

        $html
    }
);

=head2 btn_edit_word

TODO add description

=cut

has btn_edit_word => (
    is         => 'ro',
    isa        => 'Wx::Button',
    lazy_build => 1,
);

sub _build_btn_edit_word {
    my $self = shift;

    my $btn_edit_word
        = Wx::Button->new($self, wxID_ANY, 'Edit', wxDefaultPosition,
        wxDefaultSize);
    EVT_BUTTON($self, $btn_edit_word, \&edit_word);

    return $btn_edit_word;
}

=head2 btn_unlink_word

TODO add description

=cut

has btn_unlink_word => (
    is         => 'ro',
    isa        => 'Wx::Button',
    lazy_build => 1,
);

sub _build_btn_unlink_word {
    my $self = shift;

    my $btn_unlink_word
        = Wx::Button->new($self, wxID_ANY, 'Unlink', wxDefaultPosition,
        wxDefaultSize);
    EVT_BUTTON($self, $btn_unlink_word, \&unlink_word);

    return $btn_unlink_word;
}

=head2 btn_delete_word

TODO add description

=cut

has btn_delete_word => (
    is         => 'ro',
    isa        => 'Wx::Button',
    lazy_build => 1,
);

sub _build_btn_delete_word {
    my $self = shift;

    my $btn_delete_word
        = Wx::Button->new($self, wxID_ANY, 'Del', wxDefaultPosition,
        wxDefaultSize);
    EVT_BUTTON($self, $btn_delete_word, \&delete_word);

    return $btn_delete_word;
}

=head2 btn_refresh

TODO add description

=cut

has btn_refresh => (
    is      => 'ro',
    isa     => 'Wx::Button',
    lazy    => 1,
    default => sub {
        Wx::Button->new(shift, wxID_ANY, 'Refresh', wxDefaultPosition,
            wxDefaultSize)
    },
);

=head2 hbox_buttons

TODO add description

=cut

has hbox_buttons => (
    is         => 'ro',
    isa        => 'Wx::BoxSizer',
    lazy_build => 1,
);

sub _build_hbox_buttons {
    my $self = shift;

    my $hbox = Wx::BoxSizer->new(wxHORIZONTAL);
    $hbox->Add($self->btn_edit_word);
    $hbox->Add($self->btn_unlink_word);
    $hbox->Add($self->btn_delete_word);
    $hbox->Add($self->btn_refresh);

    return $hbox;
}


=head2 vbox

TODO add description

=cut

has vbox => (
    is      => 'ro',
    isa     => 'Wx::BoxSizer',
    lazy    => 1,
    default => sub {
        my $self = shift;

        my $vbox = Wx::BoxSizer->new(wxVERTICAL);
        $vbox->Add($self->html,        1, wxEXPAND | wxALL, 0);
        $vbox->Add($self->hbox_buttons, 0, wxTOP,            5);

        $vbox
    }
);

=head1 METHODS

=head2 load_word

TODO add description

=cut

sub load_word {
    my ($self, %params) = @_;

    $self->word_id($params{word_id});
    
    my $word = Database->schema->resultset('Word')->search(
        {'me.word_id' => $self->word_id},
        {prefetch     => {rel_words => ['word2_id']}}
    )->first;
    my $translate;
    for my $rel_word ($word->rel_words) {
        next unless $rel_word->word2_id or $rel_word->word2_id->word_id;
        push @{ $translate->{ $rel_word->partofspeech->abbr } } => {
            word_id      => $rel_word->word2_id->word_id,
            word         => $rel_word->word2_id->word,
            partofspeech => $rel_word->partofspeech->abbr,
            note         => $rel_word->note,
        };
    }
    $self->html->SetPage(
        $self->gen_html(
            word_id      => $word->word_id,
            word         => $word->word,
            word2        => $word->word2,
            word3        => $word->word3,
            irregular    => $word->irregular,
            partofspeech => $word->partofspeech->abbr,
            note         => $word->note,
            translate    => $translate,
        )
    );
}

=head2 edit_word

TODO add description

=cut

sub edit_word {
    my ($self) = @_;

    my $add_word_page = $self->parent->parent->p_addword;
    $add_word_page->load_word(word_id => $self->word_id);
    $self->parent->parent->new_page($add_word_page,
        'Edit Word #' . $self->word_id);
}

=head2 delete_word

TODO add description

=cut

sub delete_word {
    my ($self) = @_;

    Database->schema->resultset('Word')->delete_one($self->word_id);
    $self->parent->lookup_phrases->lookup;
}

=head2 unlink_word

TODO add description

=cut

sub unlink_word {
    my ($self) = @_;

    Database->schema->resultset('Word')->unlink_one($self->word_id);
    $self->parent->lookup_phrases->lookup;
}

=head2 gen_html

TODO add description

=cut

sub gen_html {
    my ($self, %params) = @_;

    my ($word_line, $translate, $note);

    # word line
    $word_line = '<h3>' . $params{word} . '</h3>';
    $word_line .= '<i>past simple:</i> <b> ' . $params{word2} . '</b><br> '
        if $params{word2};
    $word_line
        .= '<i>past participle:</i> <b> ' . $params{word3} . '</b><br> '
        if $params{word3};

    # translation
    for my $partofspeech (keys %{$params{translate}}) {
        $translate .= "<font size='-1'>$partofspeech</font>";
        $translate .= '<ol>';
        for my $word (@{$params{translate}{$partofspeech}}) {
            $translate
                .= '<li>'
                . $word->{word}
                . ($word->{note} ? ' <i>(' . $word->{note} . ')</i>' : '')
                . '</li>';
        }
        $translate .= '</ol>';
    }

    # note
    $note = sprintf('note: <i>%s</i>', $params{note}) if $params{note};

    # result
    $word_line . '<br><br>' . $translate . '<br><br>' . $note // '';
}

sub FOREIGNBUILDARGS {
    my ($class, @args) = @_;

    return @args;
}

sub BUILDARGS {
    my ($class, $parent) = @_;

    return {parent => $parent};
}

sub BUILD {
    my ($self, @args) = @_;

    $self->SetSizer($self->vbox);
    $self->Layout();
    $self->vbox->Fit($self);

    $self;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
