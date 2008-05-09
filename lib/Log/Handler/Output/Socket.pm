=head1 NAME

Log::Handler::Output::Socket - Send messages to a socket.

=head1 SYNOPSIS

    use Log::Handler::Output::Socket;

    my $sock = Log::Handler::Output::Socket->new(
        peeraddr    => '127.0.0.1',
        peerport    => 44444,
        proto       => 'tcp',
        timeout     => 10
    );

    $sock->log(message => $message);

=head1 DESCRIPTION

With this module it's possible to send messages over the network.

=head1 METHODS

=head2 new()

Call C<new()> to create a new Log::Handler::Output::Socket object.

The following options are possible:

=over 4

=item B<peeraddr>

The address of the server.

=item B<peerport>

The port to connect to.

=item B<proto>

The protocol you wish to use. Default is TCP.

=item B<timeout>

The timeout to send message. The default is 1.

=item B<persistent>

Enable a persistent connection to the server. The default is 1.

=item B<reconnect>

You can enable this if you want to reconnect to the server after the
connection lost. The default is 1.

=item B<dump>

Do you like to dump the message? If you enable this option then all
messages will be dumped with C<Data::Dumper>.

=item B<dumper>

Do you want to use another dumper as C<Data::Dumper>? You can do the
following as example:

    use Convert::Bencode_XS;

        dumper => sub { Convert::Bencode_XS::bencode($_[0]) }

    # or maybe

    use JSON::PC;

        dumper => sub { JSON::PC::convert($_[0]) }

=item B<connect>

This option is only useful if you want to pass your own arguments to
C<IO::Socket::INET> and don't want use C<peeraddr> and C<peerhost>.

Example:

        connect => {
            PerrAddr  => '127.0.0.1',
            PeerPort  => 44444,
            LocalPort => 44445
        }

This options are passed to C<IO::Socket::INET>.

=back

=head2 log()

Call C<log()> if you want to send a message over the socket.

Example:

    $sock->log('message');

=head2 connect()

Connect to the socket.

=head2 disconnect()

Disconnect from socket.

=head2 errstr()

This function returns the last error message.

=head1 EXPORTS

No exports.

=head1 REPORT BUGS

Please report all bugs to <jschulz.cpan(at)bloonix.de>.

If you send me a mail then add Log::Handler into the subject.

=head1 AUTHOR

Jonny Schulz <jschulz.cpan(at)bloonix.de>.

=head1 COPYRIGHT

Copyright (C) 2007 by Jonny Schulz. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

package Log::Handler::Output::Socket;

use strict;
use warnings;
use Params::Validate;
use IO::Socket::INET;
use Data::Dumper;

our $VERSION = '0.02';
our $ERRSTR  = '';

sub new {
    my $class   = shift;
    my $options = $class->_validate(@_);
    my $self    = bless $options, $class;
    if ($self->{persistent}) {
        $self->connect
            or Carp::croak $self->errstr;
    }
    return $self;
}

sub log {
    my $self    = shift;
    my $message = @_ > 1 ? {@_} : shift;
    my $socket  = ();

    if ($self->{dump}) {
        $message->{message} = $self->{dumper}(@_ > 1 ? {@_} : shift);
    }

    if ($self->{persistent} && $self->{socket}) {
        $socket = $self->{socket};
    } else {
        $socket = $self->connect
            or return undef;
    }

    local $SIG{PIPE} = 'IGNORE';
    $socket->send($message->{message}) or do {
        if ($self->{reconnect}) {
            $self->connect or return undef;
            $socket->send($message->{message})
                or return $self->_raise_error("lost connection and reconnect fails: $!");
        } else {
            return $self->_raise_error("unable to send message: $!");
        }
    };

    if (!$self->{persistent}) {
        $self->disconnect;
    }

    return 1;
}

sub connect {
    my $self = shift;
    my $opts = ();

    if (@_) {
        $opts = @_ > 1 ? {@_} : shift;
    } else {
        $opts = $self->{sock_opts};
    }

    $self->{socket} = IO::Socket::INET->new(%$opts)
        or return $self->_raise_error("unable to connect - $!");

    return $self->{socket};
}

sub disconnect {
    my $self = shift;
    $self->{socket}->close;
    $self->{socket} = undef;
}

sub errstr {
    return $ERRSTR;
}

sub DESTROY {
    my $self = shift;
    if ($self->{socket}) {
        $self->{socket}->close;
    }
}

#
# private stuff
#

sub _validate {
    my $class = shift;

    my %options = Params::Validate::validate(@_, {
        connect => {
            type => Params::Validate::HASHREF,
            optional => 1,
        },
        peeraddr => {
            type => Params::Validate::SCALAR,
            optional => 1,
        },
        peerport => {
            type => Params::Validate::SCALAR,
            optional => 1,
        },
        proto => {
            type => Params::Validate::SCALAR,
            default => 'tcp',
        },
        timeout => {
            type => Params::Validate::SCALAR,
            default => 5,
        },
        persistent => {
            type => Params::Validate::SCALAR,
            regex => qr/^[01]\z/,
            default => 1,
        },
        reconnect => {
            type => Params::Validate::SCALAR,
            regex => qr/^[01]\z/,
            default => 1,
        },
        dump => {
            type => Params::Validate::SCALAR,
            regex => qr/^[01]\z/,
            default => 0,
        },
        dumper => {
            type => Params::Validate::CODEREF,
            default => \&Dumper,
        },
    });

    if ($options{peeraddr} && $options{peerport}) {
        $options{sock_opts}{PeerAddr} = delete $options{peeraddr};
        $options{sock_opts}{PeerPort} = delete $options{peerport};
        $options{sock_opts}{Proto}    = delete $options{proto};
        $options{sock_opts}{Timeout}  = delete $options{timeout};
    } elsif (!$options{connect}) {
        Carp::croak "missing mandatory parameter connect or peeraddr/peerport";
    }

    return \%options;
}

sub _raise_error {
    $ERRSTR = $_[1];
    return undef;
}

1;
