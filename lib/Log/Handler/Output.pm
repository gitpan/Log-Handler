=head1 NAME

Log::Handler::Output - The output builder class.

=head1 SYNOPSIS

    use Log::Handler::Output;

    my $output = Log::Handler::Output->new(\%options);

=head1 DESCRIPTION

Just for internal usage!

=head1 METHODS

=head2 new()

=head2 log()

=head2 errstr()

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
our $VERSION = '0.00_06';
our $ERRSTR  = '';
our $CALLER  =  2;
our $MESSAGE = '';
our $LEVEL   = '';

use Carp;
use Devel::Backtrace;
use POSIX;
use Sys::Hostname;
use Time::HiRes;
use UNIVERSAL::require;

sub new {
    my ($class, $options) = @_;
    return bless $options, $class;
}

sub log {
    my $self       = shift;
    my $output     = $self->{output};
    my $message    = {message => ''};
    local $LEVEL   = shift;
    local $MESSAGE = join(' ', @_);

    if ($self->{message_order}) {
        foreach my $p ( @{$self->{message_order}} ) {
            if (ref($p)) {
                $message->{message} .= &$p($self);
            } else {
                $message->{message} .= $p;
            }
        }
    }

    if ($self->{message_keys}) {
        while ( my ($name, $code) = each %{$self->{pattern}} ) {
            if (ref($code)) {
                $message->{$name} = &$code($self);
            } else {
                $message->{$name} = $code; # $code is a scalar
            }
        }
    }

    if ($self->{debug} || $LEVEL eq 'TRACE') {
        $self->_add_trace($self, $message);
    } elsif ($self->{newline} && $message->{message} =~ /.\z|^\z/) {
        $message->{message} .= "\n";
    }


    $output->log($message)
        or return $self->_raise_error($output->errstr);
}

sub errstr { $ERRSTR }

#
# private stuff
#

sub _add_trace {
    my ($self, $message) = @_;

    if ( $message->{message} =~ /.\z|^\z/ ) {
        $message->{message} .= "\n";
    }

    my $bt = Devel::Backtrace->new($self->{debug_skip});

    for my $p (reverse 0..$bt->points-1) {
        $message->{message} .= ' ' x 3 . "CALL($p):";
        my $c = $bt->point($p);
        for my $k (qw/package filename line subroutine hasargs wantarray evaltext is_require/) {
            next unless defined $c->{$k};
            if ($self->{debug_mode} == 1) {
                $message->{message} .= " $k($c->{$k})";
            } elsif ($self->{debug_mode} == 2) {
                $message->{message} .= "\n" . ' ' x 6 . sprintf('%-12s', $k) . $c->{$k};
            }
        }
        $message->{message} .= "\n";
    }
}

sub _measurement {
    my $self = shift;
    if (!$self->{timeofday}) {
        $self->{timeofday} = Time::HiRes::gettimeofday;
        return 0;
    }
    my $new_time = Time::HiRes::gettimeofday;
    my $cur_time = $new_time - $self->{timeofday};
    $self->{timeofday} = $new_time;
    return sprintf('%.6f', $cur_time);
}

sub _raise_error {
    my $self = shift;
    $ERRSTR = shift;
    return undef unless $self->{die_on_errors};
    my $class = ref($self);
    Carp::croak "$class: $ERRSTR";
}

1;
