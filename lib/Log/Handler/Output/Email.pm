=head1 NAME

Log::Handler::Output::Email - Log messages as email (via Net::SMTP).

=head1 SYNOPSIS

    use Log::Handler::Output::Email;

    my $email = Log::Handler::Output::Email->new(
        host     => 'mx.bar.example',
        hello    => 'EHLO my.domain.example',
        timeout  => 120,
        debug    => 0,
        from     => 'bar@foo.example',
        to       => 'foo@bar.example',
        subject  => 'your subject',
        buffer   => 100,
        interval => 60,
    );

    $email->log($message);

=head1 DESCRIPTION

With this output module it's possible to log messages via email and it used
Net::SMTP to do it.

Net::SMTP is from Graham Barr and it does it's job very well.

=head1 METHODS

=head2 new()

Call C<new()> to create a new Log::Handler::Output::Email object.

The following options are possible:

=over 4

=item B<host>

With this option you has to define the SMTP host to connect to.

    host => 'mx.host.com'

    # or

    host => [ 'mx.host.example', 'mx.host-backup.example' ]

=item B<hello>

Identify yourself with a HELO. The default is set to C<EHLO BELO>.

=item B<timeout>

With this option you can set the maximum time in seconds to wait for a
response from the SMTP server. The default is set to 120 seconds.

=item B<from>

The sender address (MAIL FROM).

=item B<to>

The receipient address (RCPT TO).

=item B<subject>

The subject of the mail.

If no subject is set then the first 100 character of the message is used.

=item B<buffer> and B<interval>

Both options exists only for security. The thing is that it would be very bad
if something wents wrong in your program and hundreds of mails would be send.
For this reason you can set a buffer and a interval to take care.

With the buffer you can set the maximum size of the buffer in lines. If you set

    buffer => 10

then 10 messages would be buffered.

With the interval you can set the interval in seconds to flush the buffer.
C<flush> means to send the complete buffer as one email.

Note that if the buffer is full and the interval is not expired then all
further lines get lost - as a matter of course - because we don't want to blow
our memory away. To flush the buffer every time if it's full you can set the
interval to 0.

=item B<debug>

With this option it's possible to enable debugging. The informations can be
intercepted with $SIG{__WARN__}.

=back

=head2 log()

Call C<log()> if you want to log a message as email.

Example:

    $email->log('this message will be mailed');

=head2 flush()

Call C<flush()> if you want to flush the buffered lines.

=head2 sendmail()

Call C<sendmail()> if you want to send an email.

=head2 errstr()

This function returns the last error message.

=head1 DESTROY

C<DESTROY> is defined and called C<flush()>.

=head1 PREREQUISITES

    Carp
    Net::SMTP
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

=cut

package Log::Handler::Output::Email;

use strict;
use warnings;
our $VERSION = '0.00_07';
our $ERRSTR  = '';
our $TEST    =  0; # is needed to disable flush() for tests

use Data::Dumper;
use Net::SMTP;
use Params::Validate;
use Carp;

sub new {
    my $class   = shift;
    my $options = $class->_validate(@_);
    return bless $options, $class;
}

sub log {
    my $self    = shift;
    my $message = ();
    my $return  = 1;

    if (ref($_[0]) eq 'HASH') {
        $message = $_[0]->{message};
    } else {
        $message = shift;
    }

    if (@{$self->{LINE_BUFFER}} < $self->{buffer}) {
        push @{$self->{LINE_BUFFER}}, $message;
    }

    if ($self->{interval}) {
        if ($self->{time} + $self->{interval} >= time) {
            $return = $self->flush;
            # set the new time _after_ the mail is send
            # because the time that is needed to send the
            # the mail shouldn't manipulate the interval!
            $self->{time} = time;
        }
    } elsif (@{$self->{LINE_BUFFER}} == $self->{buffer}) {
        $return = $self->flush;
    }

    return $return;
}

sub flush {
    my $self = shift;
    my $message = ();
    return 1 if $TEST || !@{$self->{LINE_BUFFER}};
    while (my $line = shift @{$self->{LINE_BUFFER}}) {
        $message .= $line;
    }
    return $self->sendmail($message);
}

sub sendmail {
    my ($self, $message) = @_;
    return 1 unless length($message);
    my $subject = $self->{subject};
    my $smtp = ();

    foreach my $host (@{$self->{host}}) {
        $smtp = Net::SMTP->new(
            Host    => $host,
            Hello   => $self->{hello},
            Timeout => $self->{timeout},
            Debug   => $self->{debug},
        );
        last if $smtp;
    }

    if (!$smtp) {
        return $self->_raise_error("smtp error: unable to connect to any host");
    }

    if (!$subject) {
        $subject = substr($message, 0, 100);
    }

    my $success = 0;
    $success++ if $smtp->mail($self->{from});
    $success++ if $smtp->to($self->{to});
    $success++ if $smtp->data();
    $success++ if $smtp->datasend("From: $self->{from}\n");
    $success++ if $smtp->datasend("To: $self->{to}\n");
    $success++ if $smtp->datasend("Subject: $subject\n");
    $success++ if $smtp->datasend($message."\n");
    $success++ if $smtp->dataend();
    $success++ if $smtp->quit();

    if ($success != 9) {
        return $self->_raise_error("smtp error($success): unable to send mail to $self->{to}");
    }

    return 1;
}

sub errstr  { $ERRSTR }
sub DESTROY { $_[0]->flush }

#
# private stuff
#

sub _validate {
    my $class = shift;

    my %options = Params::Validate::validate(@_, {
        host => {
            type => Params::Validate::ARRAYREF | Params::Validate::SCALAR,
        },
        hello => {
            type => Params::Validate::SCALAR,
            default => 'EHLO BELO',
        },
        timeout => {
            type => Params::Validate::SCALAR,
            regex => qr/^\d+\z/,
            default => 120,
        },
        debug => {
            type => Params::Validate::SCALAR,
            regex => qr/^[01]\z/,
            default => 0,
        },
        from => {
            type => Params::Validate::SCALAR,
        },
        to => {
            type => Params::Validate::SCALAR,
        },
        subject => {
            type => Params::Validate::SCALAR,
            default => '',
        },
        buffer => {
            type => Params::Validate::SCALAR,
            default => 20,
        },
        interval => {
            type => Params::Validate::SCALAR,
            regex => qr/^\d+\z/,
            default => 0,
        },
    });

    if (!@{$options{host}}) {
        Carp::croak "empty array ref for option 'host' is not allowed";
    }

    if ($options{interval}) {
        $options{time} = time;
    }

    if (!ref($options{host})) {
        $options{host} = [ $options{host} ];
    }

    $options{LINE_BUFFER} = [ ];
    return \%options;
}

sub _raise_error {
    my $self = shift;
    $ERRSTR = shift;
    return undef;
}

1;
