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

The following options are possible:

=over 4

=item B<log_to>

Where do you want to log? Possible is: STDOUT and STDERR.

The default is STDOUT.

=item B<dump>

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

    Data::Dumper
    Params::Validate

=head1 EXPORTS

No exports.

=head1 REPORT BUGS

Please report all bugs to <jschulz.cpan(at)bloonix.de>.

If you send me a mail then add Log::Handler into the subject.

=head1 AUTHOR

Jonny Schulz <jschulz.cpan(at)bloonix.de>.

=head1 COPYRIGHT

Copyright (C) 2007-2008 by Jonny Schulz. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

package Log::Handler::Output::Screen;

use strict;
use warnings;
use Data::Dumper;
use Params::Validate;

our $VERSION = '0.02';
our $ERRSTR  = '';

sub new {
    my $class   = shift;
    my $options = $class->_validate(@_);
    return bless $options, $class;
}

sub log {
    my $self    = shift;
    my $message = @_ > 1 ? {@_} : shift;
    local $|=1;

    if ($self->{dump}) {
        $message->{message} = Dumper($message);
    }

    if ($self->{log_to} eq 'STDOUT') {
        print STDOUT $message->{message}
            or return $self->_raise_error($!);
    } else {
        print STDERR $message->{message}
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
