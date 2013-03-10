package Dict::Learn 0.1;
use parent 'Wx::App';

use Wx qw[:everything];
use Wx::Event qw[EVT_MENU];

use Dict::Learn::Frame;

use common::sense;

sub OnInit {
  my $self  = shift;
  my $frame = Dict::Learn::Frame->new( undef,
                                       wxID_ANY,
                                       'DictLearn v0.1',
                                       [ 200, 200 ],
                                       [ 1200, 500 ],
                                       wxDEFAULT_DIALOG_STYLE|wxRESIZE_BORDER);
  $frame->Show( 1 );
  return 1;
}

1;
__END__

=head1 NAME

Dict::Learn - The great new Dict::Learn!

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Dict::Learn;

    my $foo = Dict::Learn->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

# sub function1 {
# }

=head2 function2

=cut

# sub function2 {
# }

=head1 AUTHOR

Taras Yagniuk, C<< <mrtaryk at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dictlearn at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=dictlearn>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dict::Learn


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=dictlearn>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/dictlearn>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/dictlearn>

=item * Search CPAN

L<http://search.cpan.org/dist/dictlearn/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Taras Yagniuk.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

# End of Dict::Learn
