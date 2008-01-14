=head1 NAME

Log::Handler::Logger - The main logger class.

=head1 SYNOPSIS

    use Log::Handler::Logger;

    my $log = Log::Handler::Logger->new();

    $log->write($LEVEL, $MESSAGE);

    if ( $log->would_log($LEVEL) ) {
        $log->write($LEVEL, $MESSAGE);
    }

=head1 DESCRIPTION

This module is the main logger class.

=head2 LOG LEVELS

There are eight log levels and one special level for usage:

    DEBUG, NOTICE, INFO, WARNING, ERROR, CRITICAL, ALERT, EMERGENCY, TRACE

TRACE can be used to write caller informations to the log file so you can see
a little history foreach routine that was called. This can be very helpful to
determine errors and warnings.

=head1 METHODS

=head2 new()

Call C<new()> to create a new Log::Handler::Logger object.

The C<new()> method expected the options for the log file. Each option will
be set to a default value if not set. If this method is called with no options
then it creates an object to log to STDOUT with all default values.

=head2 write()

Call C<write()> if you want to log messages to the log file. The log level must
be passed in uppercase as first argument. The message will be logged to log file
if the log level is active.

Example:

    $log->write('WARNING', 'this message goes to the logfile');

=head2 would_log()

This method is very useful if you want to kwow if the current set of minlevel and maxlevel
would write the message to the log file. The method returns TRUE if the logger would log
it and FALSE if not. Example:

    $log->would_log('DEBUG');

=head2 errstr()

This function returns the last error message.

=head1 OPTIONS

Please look into the documentation of Log::Handler for more informations.

=head1 PREREQUISITES

    Fcntl             -  for flock(), O_APPEND, O_WRONLY, O_EXCL and O_CREATE
    POSIX             -  to generate the time stamp with strftime()
    Params::Validate  -  to validate all options
    Devel::Backtrace  -  to backtrace caller()
    Carp              -  to croak() on errors if die_on_errors is active
    Sys::Hostname     -  to get the current hostname

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

package Log::Handler::Logger;
our $VERSION = '0.00_03';
our $CALLER  = 2;
our $MESSAGE = '';

use strict;
use warnings;
use Fcntl qw( :flock O_WRONLY O_APPEND O_TRUNC O_EXCL O_CREAT );
use POSIX qw(strftime);
use Params::Validate;
use Carp qw(croak);
use Devel::Backtrace;
use Sys::Hostname;

my %LEVEL_BY_STRING = (
    NOTHING   =>  8,
    DEBUG     =>  7,
    INFO      =>  6,
    NOTICE    =>  5,
    NOTE      =>  5,
    WARNING   =>  4,
    WARN      =>  4,
    ERROR     =>  3,
    ERR       =>  3,
    CRITICAL  =>  2,
    CRIT      =>  2,
    ALERT     =>  1,
    EMERGENCY =>  0,
    EMERG     =>  0,
);

my @LEVEL_BY_NUM = qw(
    EMERGENCY
    ALERT
    CRITICAL
    ERROR
    WARNING
    NOTICE
    INFO
    DEBUG
    NOTHING
);

my %FUNCTIONS = (
    '%L'    =>  sub { $_[1] },
    '%P'    =>  sub { $$ },
    '%T'    =>  sub { shift->_set_time },
    '%H'    =>  \&Sys::Hostname::hostname,
    '%C'    =>  sub { my @c = caller($CALLER); "$c[1] line $c[2]" },
    '%N'    =>  sub { "\n" },
    '%S'    =>  sub { $0 },
);

$Log::Handler::Logger::ERRSTR = '';

sub new {
    my $class = shift;
    my $self  = $class->_new_logger(@_);

    # it's possible to set *STDOUT and *STDERR as string
    # or pass a GLOB as filename
    if (ref($self->{filename}) eq 'GLOB') {
        $self->{fh} = $self->{filename};
    } elsif ($self->{filename} eq '*STDOUT') {
        $self->{fh} = \*STDOUT;
    } elsif ($self->{filename} eq '*STDERR') {
        $self->{fh} = \*STDERR;
    }

    # if filename is a GLOB, then we force some options and return
    if (defined $self->{fh}) {
        $self->{fileopen} = 1; # never call _open() and _close()
        $self->{reopen}   = 0; # never try to reopen
        $self->{filelock} = 0; # no, we won't lock
        if ($self->{autoflush}) {
            my $oldfh = select $self->{fh};
            $| = $self->{autoflush};
            select $oldfh;
        }
        if ($self->{utf8}) {
            binmode $self->{fh}, ':utf8';
        }
        return $self;
    }

    if ($self->{mode} eq 'append') {
        $self->{mode} = O_WRONLY | O_APPEND | O_CREAT;
    } elsif ($self->{mode} eq 'excl') {
        $self->{mode} = O_WRONLY | O_EXCL | O_CREAT;
    } elsif ($self->{mode} eq 'trunc') {
        $self->{mode} = O_WRONLY | O_TRUNC | O_CREAT;
    }

    $self->{permissions} = oct($self->{permissions});

    # open the log file permanent
    if ($self->{fileopen} == 1) {
        $self->_open or return undef;
        if ($self->{reopen}) {
            $self->{inode} = (stat($self->{filename}))[1];
        }
    }

    return $self;
}

sub write {
    my $self  = shift;
    my $level = shift;

    return 1 unless $self->would_log($level);

    if (!$self->{fileopen}) {
        $self->_open or return undef;
    } elsif ($self->{reopen}) {
        $self->_checkino or return undef;
    }

    if ($self->{filelock}) {
        $self->_lock or return undef;
    }

    my $message = $self->_build_message($level, @_);

    print {$self->{fh}} $$message or do {
        if ($self->{rewrite_to_stderr}) {
            print STDERR $$message;
        }
        return $self->_raise_error("unable to print to logfile: $!");
    };

    if ($self->{filelock}) {
        $self->_unlock or return undef;
    }

    if (!$self->{fileopen}) {
        $self->_close or return undef;
    }

    return 1;
}

sub would_log {
    my ($self, $level) = @_;
    if ($level eq 'TRACE') {
        return undef unless $self->{trace};
    } else {
        return undef
            if $LEVEL_BY_STRING{$level} < $self->{minlevel}
            || $LEVEL_BY_STRING{$level} > $self->{maxlevel};
    } 
    return 1;
}

sub errstr { $Log::Handler::Logger::ERRSTR }

sub DESTROY {
    my $self = shift;
    close($self->{fh})
        if $self->{fh}
        && !ref($self->{filename})
        && $self->{filename} !~ /^\*STDOUT\z|^\*STDERR\z/;
}

#
# private stuff
#

sub _open {
    my $self = shift;

    sysopen(my $fh, $self->{filename}, $self->{mode}, $self->{permissions})
        or return $self->_raise_error("unable to open logfile $self->{filename}: $!");

    if ($self->{autoflush}) {
        my $oldfh = select $fh;
        $| = $self->{autoflush};
        select $oldfh;
    }

    if ($self->{utf8}) {
        binmode $fh, ':utf8' if $self->{utf8};
    }

    $self->{fh} = $fh;
    return 1;
}

sub _close {
    my $self = shift;

    close($self->{fh})
        or return $self->_raise_error("unable to close logfile $self->{filename}: $!");

    delete $self->{fh};
    return 1;
}

sub _checkino {
    my $self  = shift;

    if (-e $self->{filename}) {
        my $ino = (stat($self->{filename}))[1];
        unless ($self->{inode} == $ino) {
            $self->_close or return undef;
            $self->_open or return undef;
            $self->{inode} = $ino;
        }
    } else {
        $self->_close or return undef;
        $self->_open or return undef;
        $self->{inode} = (stat($self->{filename}))[1];
    }

    return 1;
}

sub _lock {
    my $self = shift;

    flock($self->{fh}, LOCK_EX)
        or return $self->_raise_error("unable to lock logfile $self->{filename}: $!");

    return 1;
}

sub _unlock {
    my $self = shift;

    flock($self->{fh}, LOCK_UN)
        or return $self->_raise_error("unable to unlock logfile $self->{filename}: $!");

    return 1;
}

sub _build_message {
    my $self  = shift;
    my $level = shift;
    my $message = '';

    if ($self->{prefix}) {
        foreach my $p ( @{$self->{prefixes}} ) {
            $message .= &$p($self, $level, @_);
        }
    }
    if (@_) {
        $message .= join(' ', @_);
    }
    if ($self->{postfix}) {
        foreach my $p ( @{$self->{postfixes}} ) {
            $message .= &$p($self, $level, @_);
        }
    }
    if ($self->{debug} || $level eq 'TRACE') {
        $message .= "\n" if $message =~ /.\z|^\z/;
        my $bt = Devel::Backtrace->new($self->{debug_skip});
        for my $p (reverse 0..$bt->points-1) {
            $message .= ' ' x 3 . "CALL($p):";
            my $c = $bt->point($p);
            for my $k (qw/package filename line subroutine hasargs wantarray evaltext is_require/) {
                next unless defined $c->{$k};
                if ($self->{debug_mode} == 1) {
                    $message .= " $k($c->{$k})";
                } elsif ($self->{debug_mode} == 2) {
                    $message .= "\n" . ' ' x 6 . sprintf('%-12s', $k) . $c->{$k};
                }
            }
            $message .= "\n";
        }
    } elsif ($self->{newline} && $message =~ /.\z|^\z/) { # I hope that works on the most OSs
        $message .= "\n";
    }

    return \$message;
}

sub _set_time {
    my $self = shift;
    my $time = strftime($self->{timeformat}, localtime);
    return $time;
}

sub _new_logger {
    my $class    = shift;
    my $bool_rx  = qr/^[10]\z/;
    my $level_rx = qr/^([0-8]|nothing|debug|info|notice|note|warning|warn
                       |error|err|critical|crit|alert|emergency|emerg)\z/x;

    my %options = Params::Validate::validate(@_, {
        filename => {
            type => Params::Validate::SCALAR | Params::Validate::GLOBREF,
            default => '*STDOUT',
        },
        filelock => {
            type => Params::Validate::SCALAR,
            regex => $bool_rx,
            default => 1,
        },
        fileopen => {
            type => Params::Validate::SCALAR,
            regex => $bool_rx,
            default => 1,
        },
        reopen => {
            type  => Params::Validate::SCALAR,
            regex => $bool_rx,
            default => 1,
        },
        mode => {
            type => Params::Validate::SCALAR,
            regex => qr/^(append|excl|trunc)\z/,
            default => 'excl',
        },
        autoflush => {
            type => Params::Validate::SCALAR,
            regex => $bool_rx,
            default => 1,
        },
        permissions => {
            type => Params::Validate::SCALAR,
            regex => qr/^[0-7]{3,4}\z/,
            default => '0640',
        },
        timeformat => {
            type => Params::Validate::SCALAR,
            default => '%b %d %H:%M:%S',
        },
        prefix => {
            type => Params::Validate::SCALAR,
            default => '%T [%L] ',
        },
        postfix => {
            type => Params::Validate::SCALAR,
            default => '',
        },
        newline => {
            type => Params::Validate::SCALAR,
            regex => $bool_rx,
            default => 0,
        },
        minlevel => {
            type => Params::Validate::SCALAR,
            regex => $level_rx,
            default => 0,
        },
        maxlevel => {
            type => Params::Validate::SCALAR,
            regex => $level_rx,
            default => 4,
        },
        rewrite_to_stderr => {
            type => Params::Validate::SCALAR,
            regex => $bool_rx,
            default => 0,
        },
        die_on_errors => {
            type => Params::Validate::SCALAR,
            regex => $bool_rx,
            default => 1,
        },
        debug => {
            type => Params::Validate::SCALAR,
            regex => $bool_rx,
            default => 0,
        },
        debug_mode => {
            type => Params::Validate::SCALAR,
            regex => qr/^[12]\z/,
            default => 1,
        },
        debug_skip => {
            type => Params::Validate::SCALAR,
            regex => qr/^\d+\z/,
            default => 0,
        },
        utf8 => {
            type => Params::Validate::SCALAR,
            regex => $bool_rx,
            default => 0,
        },
        trace => {
            type => Params::Validate::SCALAR,
            regex => $bool_rx,
            default => 1,
        },
    });

    foreach my $level (qw/minlevel maxlevel/) {
        if ($options{$level} !~ /^\d\z/) {
            $options{$level} =
                $LEVEL_BY_STRING{ uc($options{$level}) };
        }
    }

    foreach my $p (qw/prefix postfix/) {
        next unless length($options{$p});
        $options{$p}  =~ s/<--LEVEL-->/%L/g;
        foreach my $c ( split /(%[A-Z])/, $options{$p} ) {
            if ( exists $FUNCTIONS{$c} ) {
                push @{$options{"${p}es"}}, $FUNCTIONS{$c};
            } else {
                push @{$options{"${p}es"}}, sub { $c };
            }
        }
    }

    return bless \%options, $class;
}

sub _raise_error {
    my $self = shift;
    $Log::Handler::Logger::ERRSTR = shift;
    return undef unless $self->{die_on_errors};
    my $class = ref($self);
    croak "$class: ".$Log::Handler::Logger::ERRSTR;
}

1;
