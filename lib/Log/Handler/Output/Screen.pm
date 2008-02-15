=head1 NAME

Log::Handler::Output::Screen - Log messages to the screen.

=head1 SYNOPSIS

    use Log::Handler::Output::Screen;

    my $screen = Log::Handler::Output::Screen->new(
        log_to => 'STDERR',
        dump   => 1,
    );

    $screen->log($message);

=head1 DESCRIPTION

This output module makes it possible to log messages to your screen.

=head1 METHODS

=head2 new()

Call C<new()> to create a new Log::Handler::Output::Screen object.

=head3 OPTIONS

=over 4

=item log_to

Where do you want to log? Possible is: STDOUT and STDERR.

The default is STDOUT.

=item dump

Set this option to 1 if you want that the message will be dumped with
C<Data::Dumper> to the screen.

=back

=head2 log()

Call C<log()> if you want to log a message to the screen.

Example:

    $screen->log('this message goes to the screen');

=head2 errstr()

This function returns the last error message.

=head1 PREREQUISITES

    Carp
    Data::Dumper
    Params::Validate

=head1 EXPORTS

No exports.

=head1 REPORT BUGS

Please report all bugs to <jschulz.cpan(at)bloonix.de>.

=head1 AUTHOR

Jonny Schulz <jschulz.cpan(at)bloonix.de>.

=head1 QUESTIONS

Do you have any questions or ideas?

MAIL: <jschulz.cpan(at)bloonix.de>

If you send me a mail then add Log::Handler into the subject.

=head1 COPYRIGHT

Copyright (C) 2007 by Jonny Schulz. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

package Log::Handler::Output::Screen;

use strict;
use warnings;
use Data::Dumper;
use Params::Validate;
our $VERSION  = '0.00_03';
our $ERRSTR   = '';

sub new {
    my $class   = shift;
    my $options = $class->_validate(@_);
    return bless $options, $class;
}

sub log {
    my $self    = shift;
    my $message = ();

    if ($self->{dump}) {
        $message = Dumper(shift);
    } else {
        $message = shift->{message};
    }

    if ($self->{log_to} eq 'STDOUT') {
        print STDOUT $message
            or return $self->_raise_error($!);
    } else {
        print STDERR $message
            or return $self->_raise_error($!);
    }

    return 1;
}

sub errstr { $ERRSTR }

#
# private stuff
#

sub _validate {
    my $class   = shift;

    my %options = Params::Validate::validate(@_, {
        log_to => {
            type => Params::Validate::SCALAR,
            regex => qr/^STD(?:ERR|OUT)\z/,
            default => 'STDOUT',
        },
        dump => {
            type => Params::Validate::SCALAR,
            regex => qr/^[01]\z/,
            default => 0,
        },
    });

    return \%options;
}

1;
