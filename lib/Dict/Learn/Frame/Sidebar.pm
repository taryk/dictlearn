package Dict::Learn::Frame::Sidebar 0.1;

use Wx qw[:everything];
use Wx::Event qw[:everything];
use Wx::Html;

use Moose;
use MooseX::NonMoose;
extends 'Wx::Panel';

use Carp qw[croak confess];
use Data::Printer;

use common::sense;

=item parent

=cut

has parent => (
    is  => 'ro',
    isa => 'Dict::Learn::Frame::SearchWords',
);

=item html

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

=item btn_refresh

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

=item vbox

=cut

has vbox => (
    is      => 'ro',
    isa     => 'Wx::BoxSizer',
    lazy    => 1,
    default => sub {
        my $self = shift;

        my $vbox = Wx::BoxSizer->new(wxVERTICAL);
        $vbox->Add($self->html,        1, wxEXPAND | wxALL, 0);
        $vbox->Add($self->btn_refresh, 0, wxTOP,            5);

        $vbox
    }
);

sub load_word {
    my ($self, %params) = @_;

    my $word = $main::ioc->lookup('db')->schema->resultset('Word')->search(
        {'me.word_id' => $params{word_id}},
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
                . ($word->{note} ? '<i>(' . $word->{note} . ')</i>' : '')
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
