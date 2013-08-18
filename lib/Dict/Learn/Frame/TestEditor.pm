package Dict::Learn::Frame::TestEditor 0.1;

use Wx qw[:everything];
use Wx::Event qw[:everything];

use Data::Printer;

use Moose;
use MooseX::NonMoose;
extends 'Wx::Panel';

use Carp qw[ croak confess ];

use common::sense;

sub TEST_ID { 1 }

=item parent

=cut

has parent => (
    is  => 'ro',
    isa => 'Dict::Learn::Frame',
);

=item test_groups

=cut

has test_groups => (
    is         => 'ro',
    isa        => 'Wx::ListCtrl',
    lazy_build => 1,
);

sub _build_test_groups {
    my $self = shift;

    my $test_groups = Wx::ListCtrl->new($self, wxID_ANY, wxDefaultPosition,
        wxDefaultSize, wxLC_REPORT | wxLC_HRULES | wxLC_VRULES);

    return $test_groups;
}

=item test_words

=cut

has test_words => (
    is         => 'ro',
    isa        => 'Wx::ListCtrl',
    lazy_build => 1,
   );

sub _build_test_words {
    my $self = shift;
    
    my $test_words = Wx::ListCtrl->new($self, wxID_ANY, wxDefaultPosition,
        wxDefaultSize, wxLC_REPORT | wxLC_HRULES | wxLC_VRULES);
    
    return $test_words;
}

=item btn_move_left

=cut

has btn_move_left => (
    is      => 'ro',
    isa     => 'Wx::Button',
    lazy    => 1,
    default => sub {
        Wx::Button->new(shift, wxID_ANY, '<- Add', wxDefaultPosition,
            wxDefaultSize)
    },
);

=item btn_move_right

=cut

has btn_move_right => (
    is      => 'ro',
    isa     => 'Wx::Button',
    lazy    => 1,
    default => sub {
        Wx::Button->new(shift, wxID_ANY, '-> Remove', wxDefaultPosition,
            wxDefaultSize)
    },
);

=item vbox_btn

=cut

has vbox_btn => (
    is         => 'ro',
    isa        => 'Wx::BoxSizer',
    lazy_build => 1,
);

sub _build_vbox_btn {
    my $self = shift;

    my $vbox_btn = Wx::BoxSizer->new(wxVERTICAL);
    $vbox_btn->Add($self->btn_move_left,  0, wxLEFT, 5);
    $vbox_btn->Add($self->btn_move_right, 0, wxLEFT, 5);

    return $vbox_btn;
}

=item word_list

=cut

has word_list => (
    is         => 'ro',
    isa        => 'Wx::ListCtrl',
    lazy_build => 1,
);

sub _build_word_list {
    my $self = shift;
    
    my $word_list = Wx::ListCtrl->new($self, wxID_ANY, wxDefaultPosition,
        wxDefaultSize, wxLC_REPORT | wxLC_HRULES | wxLC_VRULES);
    
    return $word_list;
}

=item hbox

=cut

has hbox => (
    is         => 'ro',
    isa        => 'Wx::BoxSizer',
    lazy_build => 1,
);

sub _build_hbox {
    my $self = shift;

    my $hbox = Wx::BoxSizer->new(wxHORIZONTAL);
    $hbox->Add($self->test_groups, 1,          wxEXPAND, 0  );
    $hbox->Add($self->test_words,  1, wxLEFT | wxEXPAND, 5  );
    $hbox->Add($self->vbox_btn,    0, wxTOP,             25 );
    $hbox->Add($self->word_list,   1, wxLEFT | wxEXPAND, 5  );

    return $hbox;
}

sub FOREIGNBUILDARGS {
    my ($class, $parent, @args) = @_;

    return @args;
}

sub BUILDARGS {
    my ($class, $parent) = @_;

    return { parent => $parent };
}

sub BUILD {
    my ($self, @args) = @_;
 
    # layout
    $self->SetSizer($self->hbox);
    $self->hbox->Fit($self);
    $self->Layout();

    Dict::Learn::Dictionary->cb(
        sub {
            $self->init();
        }
    );
}

sub init {
    my ($self) = @_;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 NAME

Dict::Learn::Frame::TestEditor - Perl extension for blah blah blah

=head1 SYNOPSIS

   use Dict::Learn::Frame::TestEditor;
   blah blah blah

=head1 DESCRIPTION

Stub documentation for Dict::Learn::Frame::TestEditor, 

Blah blah blah.

=head2 EXPORT

None by default.

=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

taryk, E<lt>mrtaryk@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by taryk

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut
