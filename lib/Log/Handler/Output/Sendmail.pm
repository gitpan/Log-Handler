=head1 NAME

Log::Handler::Output::Sendmail - Log messages with sendmail.

=head1 SYNOPSIS

    use Log::Handler::Output::Sendmail;

    my $email = Log::Handler::Output::Sendmail->new(
        from    => 'bar@foo.example',
        to      => 'foo@bar.example',
        subject => 'your subject',
    );

    $email->log(message => $message);

=head1 DESCRIPTION

With this output module it's possible to log messages via C<sendmail>.

=head1 METHODS

=head2 new()

Call C<new()> to create a new Log::Handler::Output::Sendmail object.

The following options are possible:

=over 4

=item B<from>

The sender address (From).

=item B<to>

The receipient address (To).

=item B<cc>

Carbon Copy (Cc).

=item B<bcc>

Blind Carbon Copy (Bcc)

=item B<subject>

The subject of the mail.

=item B<sender>

This option is identical with C<sendmail -f>.

=item B<header>

With this options it's possible to set your own header.

    my $email = Log::Handler::Output::Sendmail->new(
        from   => 'bar@foo.example',
        to     => 'foo@bar.example',
        header => 'Content-Type: text/plain; charset= UTF-8',
    );

Or

    my $email = Log::Handler::Output::Sendmail->new(
        header => {
            From    => 'bar@foo.example',
            To      => 'foo@bar.example',
            Subject => 'my subject',
            'Content-Type' => text/plain; charset= UTF-8',
        }
    );

Or

    my $email = Log::Handler::Output::Sendmail->new(
        header => [
            'From: bar@foo.example',
            'To: foo@bar.example',
            'Subject: my subject',
            'Content-Type: text/plain; charset= UTF-8',
        ]
    );

=item B<sendmail>

The default is set to C</usr/sbin/sendmail>.

=item B<params>

Parameters for C<sendmail>.

The default is set to C<-t>.

=item B<maxsize>

Set the maximum size of the buffer in bytes.

All messages will be buffered and if C<maxsize> is exceeded
the buffer is flushed and the messages will be send as email.

The default is set to 1048576 bytes.

Set 0 if you want no buffering and send a mail
for each log message.

=item B<debug>

Set 1 if you want to enable debugging.

The messages can be fetched with $SIG{__WARN__}.

=back

=head2 log()

Call C<log()> if you want to log a message as email.

    $email->log(message => "this message will be mailed");

=head2 flush()

Call C<flush()> if you want to flush the buffered messages.

=head2 reload()

Reload with a new configuration.

=head2 errstr()

This function returns the last error message.

=head1 DESTROY

C<DESTROY> is defined and called C<flush()>.

=head1 PREREQUISITES

    Carp
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

package Log::Handler::Output::Sendmail;

use strict;
use warnings;
use Carp;
use Params::Validate;

our $VERSION = "0.03";
our $ERRSTR  = "";
our $TEST    =  0; # is needed to disable flush() for tests

sub new {
    my $class = shift;
    my $opts  = $class->_validate(@_);
    my $self  = bless $opts, $class;

    $self->{message} = "";
    $self->{length}  = 0;

    return $self;
}

sub log {
    my $self    = shift;
    my $class   = ref($self);
    my $message = @_ > 1 ? {@_} : shift;
    my $length  = length($message->{message});

    if (!$self->{maxsize}) {
        if ($self->{debug}) {
            warn "$class: maxsize disabled, no buffering";
        }
        $self->{message} = $message->{message};
        return $self->_sendmail;
    }

    if ($length + $self->{length} > $self->{maxsize}) {
        if ($self->{debug}) {
            warn "$class: maxsize of $self->{maxsize} reached";
        }
        $self->flush;
    }

    $self->{message} .= $message->{message};
    $self->{length}  += $length;

    if ($self->{debug}) {
        warn "$class: buffer new message, length $length";
        warn "$class: buffer length: $self->{length}";
    }

    return 1;
}

sub flush {
    my $self = shift;

    if ($TEST || !$self->{message}) {
        return 1;
    }

    return $self->_sendmail;
}

sub reload {
    my $self = shift;
    my $opts = ();

    eval { $opts = $self->_validate(@_) };

    if ($@) {
        return $self->_raise_error($@);
    }

    $self->flush;

    foreach my $key (keys %$opts) {
        $self->{$key} = $opts->{$key};
    }

    $self->{message} = "";
    $self->{length}  = 0;

    return 1;
}

sub errstr {
    return $ERRSTR;
}

sub DESTROY {
    my $self = shift;
    $self->flush;
}

#
# private stuff
#

sub _sendmail {
    my $self     = shift;
    my $class    = ref($self);
    my $header   = $self->{header};
    my $sendmail = $self->{sendmail};

    if ($self->{params}) {
        $sendmail .= " $self->{params}";
    }

    if ($self->{debug}) {
        warn "$class: call <$sendmail>";
        warn "$class: header <$header>";
        warn "$class: message $self->{length} bytes";
    }

    open my $fh, "|$sendmail"
        or return $self->raise_error("unable to execute '$self->{sendmail}' - $!");

    my $ret = print $fh $header, "\n", $self->{message};

    $self->{message} = "";
    $self->{length}  = 0;

    if (!$ret) {
        return $self->raise_error("unable to write to stdin - $!");
    }

    close $fh;

    return 1;
}

sub _validate {
    my $class = shift;

    my %options = Params::Validate::validate(@_, {
        sender => {
            type => Params::Validate::SCALAR,
            optional => 1,
        },
        from => {
            type => Params::Validate::SCALAR,
            optional => 1,
        },
        to => {
            type => Params::Validate::SCALAR,
            optional => 1,
        },
        cc => {
            type => Params::Validate::SCALAR,
            optional => 1,
        },
        bcc => {
            type => Params::Validate::SCALAR,
            optional => 1,
        },
        subject => {
            type => Params::Validate::SCALAR,
            optional => 1,
        },
        header => {
            type => Params::Validate::SCALAR
                | Params::Validate::ARRAYREF
                | Params::Validate::HASHREF,
            optional => 1,
        },
        maxsize => {
            type => Params::Validate::SCALAR,
            regex => qr/^\d+\z/,
            default => 1048576,
        },
        sendmail => {
            type => Params::Validate::SCALAR,
            default => "/usr/sbin/sendmail",
        },
        params => {
            type => Params::Validate::SCALAR,
            default => "-t",
        },
        debug => {
            type => Params::Validate::SCALAR,
            regex => qr/^[01]\z/,
            default => 0,
        },
    });

    if (!-x $options{sendmail}) {
        Carp::croak "'$options{sendmail}' is not executable";
    }

    if ($options{subject}) {
        $options{subject} =~ s/\n/ /g;
        $options{subject} =~ s/(.{78})/$1\n /;

        if (length($options{subject}) > 998) {
            warn "Subject to long for email!";
            $options{subject} = substr($options{subject}, 0, 998);
        }
    }

    if (ref($options{header})) {
        my $header = ();

        if (ref($options{header}) eq "HASH") {
            foreach my $n (keys %{ $options{header} }) {
                $header .= "$n: $options{header}{$n}\n";
            }
        } elsif (ref($options{header}) eq "ARRAY") {
            foreach my $h (@{ $options{header} }) {
                $header .= "$h\n";
            }
        }

        $options{header} = $header;
    }

    if ($options{header} && $options{header} !~ /(?:\015|\012)\z/) {
        $options{header} .= "\n";
    }

    foreach my $opt (qw/from to cc bcc subject/) {
        if ($options{$opt}) {
            $options{header} .= ucfirst($opt).": $options{$opt}\n";
        }
    }

    if ($options{sender}) {
        $options{sendmail} .= " -f $options{sender}";
    }

    return \%options;
}

sub _raise_error {
    $ERRSTR = $_[1];
    return undef;
}

1;
