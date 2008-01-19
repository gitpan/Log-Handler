=head1 NAME

Log::Handler::Logger::Forward - Log messages as email.

=head1 SYNOPSIS

    use Log::Handler::Logger::Forward

    my $forwarder = Log::Handler::Logger::Forward->new(
        forward_to => [ sub { }, sub { } ],
    );

    $forwarder->write($message);

=head1 DESCRIPTION

Forward messages to sub routines.

=head1 METHODS

=head2 new()

Call C<new()> to create a new Log::Handler::Logger::Forward object.

The C<new()> method expected the options for the forwarder.

=head2 write()

Call C<write()> if you want to forward messages to the subroutines.

Example:

    $forwarder->write('this message will be forwarded to all sub routines');

=head2 errstr()

This function returns the last error message.

=head1 OPTIONS

=head2 forward_to

This option excepts a array reference with code references.

=head1 PREREQUISITES

    Carp
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

package Log::Handler::Logger::Forward;

use strict;
use warnings;
our $VERSION = '0.00_01';
our $ERRSTR  = '';

use Carp;
use Params::Validate;

sub new {
    my $class = shift;
    my $self  = $class->_new_forward(@_);
    return $self;
}

sub write {
    my ($self, $message) = @_;
    my $to = $self->{forward_to};

    foreach my $coderef ( @$to ) {
        eval { &$coderef($$message) };
        if ($@) {
            return $self->_raise_error($@);
        }
    }

    return 1;
}

sub errstr { $ERRSTR }

#
# private stuff
#

sub _new_forward {
    my $class   = shift;

    my %options = Params::Validate::validate(@_, {
        forward_to => {
            type => Params::Validate::ARRAYREF,
        },
    });

    foreach my $to ( @{$options{forward_to}} ) {
        if (ref($to) ne 'CODE') {
            Carp::croak "not a coderef";
        }
    }

    return bless \%options, $class;
}

sub _raise_error {
    my $self = shift;
    $ERRSTR = shift;
    return undef;
}

1;
