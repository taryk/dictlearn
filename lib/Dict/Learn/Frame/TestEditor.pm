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
