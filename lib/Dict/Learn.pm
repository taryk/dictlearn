package Dict::Learn 0.1;
use parent 'Wx::App';

use Wx qw[:everything];
use Wx::Event qw[EVT_MENU];

use Dict::Learn::Frame;

use common::sense;
use namespace::autoclean;

=head1 NAME

Dict::Learn - The great new Dict::Learn!

=head1 VERSION

Version 0.01

=head1 DESCRIPTION

TODO add description

=head1 FUNCTIONS

=head2 OnInit

TODO add description

=cut

sub OnInit {
    my $self  = shift;
    my $frame = Dict::Learn::Frame->new(
        undef, wxID_ANY,
        'DictLearn v0.1',
        [200,  200],
        [1200, 500],
        wxDEFAULT_DIALOG_STYLE | wxRESIZE_BORDER
    );
    $frame->Show(1);
    return 1;
}

=head1 AUTHOR

Taras Iagniuk, C<< <mrtaryk at gmail.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Taras Iagniuk.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
