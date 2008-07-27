=head1 NAME

Log::Handler::Output - The output builder class.

=head1 DESCRIPTION

Just for internal usage!

=head1 METHODS

=head2 new()

=head2 log()

=head2 flush()

=head2 errstr()

=head1 PREREQUISITES

    Carp
    UNIVERSAL
    Devel::Backtrace

=head1 AUTHOR

Jonny Schulz <jschulz.cpan(at)bloonix.de>.

=head1 COPYRIGHT

Copyright (C) 2007 by Jonny Schulz. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

package Log::Handler::Output;

use strict;
use warnings;
use Carp;
use UNIVERSAL;
use Devel::Backtrace;

our $VERSION = '0.04';
our $ERRSTR  = '';

sub new {
    my ($class, $options, $output) = @_;
    my $self = bless $options, $class;
    $self->{output} = $output;
    return $self;
}

sub log {
    my $self    = shift;
    my $level   = shift;
    my $wanted  = {message=>join(' ', @_)||''};
    my $output  = $self->{output};
    my $pattern = $self->{pattern};
    my $message = { };

    if ($self->{filter_caller}) {
        my $caller = (caller(1+$Log::Handler::CALLER_LEVEL))[0];
        return 1 if $caller !~ $self->{filter_caller};
    }

    # The patterns must be generated for each output. The reason
    # is that each output can have their own time/date format
    # and the code which is executed can return another value.
    foreach my $r (@{$self->{wanted_pattern}}) {
        if (ref($r->{code})) {
            $wanted->{$r->{name}} = &{$r->{code}}($self, $level);
        } else {
            $wanted->{$r->{name}} = $r->{code};
        }
    }

    if ($self->{message_layout}) {
        &{$self->{message_layout_code}}($wanted, $message);
    } else {
        $message->{message} = $wanted->{message};
    }

    if ($self->{message_pattern}) {
        &{$self->{message_pattern_code}}($wanted, $message);
    }

    if ($self->{debug_trace} || $Log::Handler::TRACE) {
        $self->_add_trace($message);
    } elsif ($self->{newline} && $message->{message} =~ /.\z/) {
        $message->{message} .= "\n";
    }

    if ($self->{filter_message}) {
        $self->_filter_msg($message) or return 1;
    }

    if ($self->{prepare_message}) {
        # each output can have an own prepare function. for this reason
        # the message is passed as hash and not as a reference.
        my $prepare_message = $self->_prepare_message(%$message)
            or return $self->_raise_error($output->errstr);
        $output->log($prepare_message)
            or return $self->_raise_error($output->errstr);
    } else {
        $output->log($message)
            or return $self->_raise_error($output->errstr);
    }

    return 1;
}

sub flush {
    my $self   = shift;
    my $output = $self->{output};

    if ( UNIVERSAL::can($output, 'flush') ) {
        $output->flush
            or return $self->_raise_error($output->errstr);
    }

    return 1;
}

sub errstr { $ERRSTR }

#
# private stuff
#

sub _add_trace {
    my ($self, $message) = @_;

    if ( $message->{message} =~ /.\z/ ) {
        $message->{message} .= "\n";
    }

    my $bt = Devel::Backtrace->new($self->{debug_skip});

    foreach my $point (reverse 0..$bt->points-1) {
        $message->{message} .= ' ' x 3 . "CALL($point):";
        my $caller = $bt->point($point);
        foreach my $key (qw/package filename line subroutine hasargs wantarray evaltext is_require/) {
            next unless defined $caller->{$key};
            if ($self->{debug_mode} == 1) { # line mode
                $message->{message} .= " $key($caller->{$key})";
            } elsif ($self->{debug_mode} == 2) { # block mode
                $message->{message} .= "\n" . ' ' x 6 . sprintf('%-12s', $key) . $caller->{$key};
            }
        }
        $message->{message} .= "\n";
    }
}

sub _prepare_message {
    my $self = shift;
    my $msg  = {@_};
    my $code = $self->{prepare_message};
    eval { &$code($msg) };
    return $@ ? $self->_raise_error($@) : $msg;
}

sub _filter_msg {
    my ($self, $message) = @_;
    my $filter = $self->{filter_message};
    my $result = $filter->{result};
    my $code   = $filter->{code};
    my $return = ();

    if (!$filter->{condition}) {
        $return = &$code($message) || 0;
    } else {
        foreach my $match ( keys %$result ) {
            $result->{$match} =
                $message->{message} =~ /$filter->{$match}/ || 0;
        }
        $return = &$code($result);
    }

    return $return;
}

sub _raise_error {
    my $self = shift;
    $ERRSTR = shift;
    return undef unless $self->{die_on_errors};
    my $class = ref($self);
    Carp::croak "$class: $ERRSTR";
}

1;
