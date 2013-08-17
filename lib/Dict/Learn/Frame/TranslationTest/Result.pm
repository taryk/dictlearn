package Dict::Learn::Frame::TranslationTest::Result 0.1;

use Wx qw[:everything];
use Wx::Event qw[:everything];

use Moose;
use MooseX::NonMoose;
extends 'Wx::Dialog';

use Data::Printer;

use common::sense;

=item parent

=cut

has parent => (
    is       => 'ro',
    isa      => 'Dict::Learn::Frame::TranslationTest',
    required => 1,
);

=item hbox

=cut

has hbox => (
    is      => 'ro',
    isa     => 'Wx::BoxSizer',
    default => sub { Wx::BoxSizer->new(wxHORIZONTAL) },
);

=item vbox

=cut

has vbox => (
    is      => 'ro',
    isa     => 'Wx::BoxSizer',
    default => sub { Wx::BoxSizer->new(wxVERTICAL) },
);

=item btn_ok

=cut

has btn_ok => (
    is      => 'ro',
    isa     => 'Wx::Button',
    default => sub {
        Wx::Button->new(shift, wxID_OK, 'OK', wxDefaultPosition,
            wxDefaultSize);
    },
);

=item btn_cancel

=cut

has btn_cancel => (
    is      => 'ro',
    isa     => 'Wx::Button',
    default => sub {
        Wx::Button->new(shift, wxID_CANCEL, 'Cancel', wxDefaultPosition,
            wxDefaultSize);
    },
);

=item listbox

=cut

has listbox => (
    is      => 'ro',
    isa     => 'Wx::SimpleHtmlListBox',
    default => sub {
        Wx::SimpleHtmlListBox->new(shift, wxID_ANY, wxDefaultPosition,
            [350, 300],
            [], wxLB_MULTIPLE);
    },
);

sub FOREIGNBUILDARGS {
    my ($class, @args) = @_;

    return @args;
}

sub BUILDARGS {
    my ($class, $parent) = @_;

    return { parent => $parent };
}

sub BUILD {
    my ($self, @args) = @_;

    $self->hbox->Add($self->btn_ok,     0, wxEXPAND, 0);
    $self->hbox->Add($self->btn_cancel, 0, wxEXPAND, 0);

    $self->vbox->Add($self->listbox, 0, wxALL | wxEXPAND, 5);
    $self->vbox->Add($self->hbox,    0, wxALL | wxEXPAND, 5);

    $self->SetSizer($self->vbox);
    $self->Layout();
    $self->vbox->Fit($self);
}

sub fill_result {
    my ($self, @res) = @_;

    $self->listbox->Clear();
    for my $item (@res) {

        # TODO add note
        $self->listbox->Append(
            sprintf '<div style="border: 1px solid black">'
                . '<h3>%i</h3><br>'
                . '<font color="#cccccc"><u>text</u></font> %s<br>'
                . '<font color="#cccccc"><u>answer</u></font> <b>%s</b><br>'
                . '<font color="#cccccc"><u>match most</u></font> <b>%s</b><br>%s'
                . '</div>',
            $item->{score},
            $item->{word},
            $item->{user}[0][0],
            $item->{note},
            join ', ',
            @{$item->{other}}
        );
    }

    $self;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
