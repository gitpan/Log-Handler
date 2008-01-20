=head1 NAME

Log::Handler::Logger - The main logger class.

=head1 SYNOPSIS

    use Log::Handler::Logger;

    my $log = Log::Handler::Logger->new(
        file => {
            filename => 'file.log',
            maxlevel => 'debug',
            minlevel => 'warn',
            newline  => 1,
        }
    );

    $log->write($LEVEL, $MESSAGE);

    if ( $log->would_log($LEVEL) ) {
        $log->write($LEVEL, $MESSAGE);
    }

=head1 DESCRIPTION

This module is the main logger class.

=head2 LOG LEVELS

There are eight log levels and two special level for usage:

    DEBUG, NOTICE, INFO, WARNING, ERROR, CRITICAL, ALERT, EMERGENCY, FATAL, TRACE

TRACE can be used to append caller informations to the message.

FATAL is the same as CRITICAL, ALERT and EMERGENCY.

=head1 METHODS

=head2 new()

Call C<new()> to create a new Log::Handler::Logger object.

The method expects the options for the logger. Each option will be set to a default
value if not set. If this method is called with no options then it creates an object
to log to STDOUT with all default values.

=head2 write()

Call C<write()> if you want to log messages. The log level must be passed uppercase
as first argument. The message will be logged to log file if the log level is active.

Example:

    $log->write('WARNING', 'this message goes to the logfile');

=head2 would_log()

This method is very useful if you want to kwow if the current set of C<minlevel> and
C<maxlevel> would log the message. The method returns TRUE if the logger would log
it and FALSE if not. Example:

    $log->would_log('DEBUG');

=head2 errstr()

This function returns the last error message.

=head1 OPTIONS

The logger options are documented in L<Log::Handler>.

=head1 PREREQUISITES

    Carp
    Devel::Backtrace
    Params::Validate
    POSIX
    Time::HiRes
    Sys::Hostname
    UNIVERSAL::require

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

use strict;
use warnings;
our $VERSION = '0.00_05';
our $CALLER  =  2;
our $MESSAGE = '';
our $ERRSTR  = '';

use POSIX;
use Params::Validate;
use Carp;
use Devel::Backtrace;
use Sys::Hostname;
use Time::HiRes;
use UNIVERSAL::require;

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

my %PLACEHOLDERS = (
    L  => {     name => 'level',
                code => sub { $_[1] } },
    P  => {     name => 'pid',
                code => sub { $$ } },
    T  => {     name => 'timestamp',
                code => sub { shift->_set_time } },
    H  => {     name => 'hostname',
                code => \&Sys::Hostname::hostname },
    C  => {     name => 'caller',
                code => sub { my @c = caller($CALLER); "$c[1], line $c[2]" } },
    N  => {     name => 'newline',
                code => sub { "\n" } },
    p  => {     name => 'progname',
                code => sub { $0 } },
    t  => {     name => 'time',
                code => sub { shift->_measurement } }
);

my @LOGGER_OPTIONS = qw(
    timeformat
    prefix
    postfix
    newline
    minlevel
    maxlevel
    die_on_errors
    setinfo
    debug
    debug_mode
    debug_skip
    trace
);

my %AVAILABLE_LOGGER = (
    file    => 'Log::Handler::Logger::File',
    email   => 'Log::Handler::Logger::Email',
    dbi     => 'Log::Handler::Logger::DBI',
    socket  => 'Log::Handler::Logger::Socket',
    forward => 'Log::Handler::Logger::Forward',
);

my %LOADED_MODULES = ();

use constant BOOL_RX  => qr/^\d+\z/;

use constant LEVEL_RX => qr/^(?:
    8 | nothing   |
    7 | debug     |
    6 | info      |
    5 | notice    | note |
    4 | warning   | warn |
    3 | error     | err  |
    2 | critical  | crit |
    1 | alert     |
    0 | emergency | emerg
)\z/x;

sub new {
    @_ > 2 or Carp::croak 'Usage: new( $type => \%options )';
    my $class = shift;
    my $self  = $class->_new_logger(@_);
    return $self;
}

sub write {
    my $self  = shift;
    my $level = shift;

    return 1 unless $self->would_log($level);

    my $logger  = $self->{logger};
    my $message = $self->_build_message($level, @_);

    $logger->write($message) or
        return $self->_raise_error($logger->errstr);

    return 1;
}

sub would_log {
    my ($self, $level) = @_;
    my $active_levels = $self->{active_levels};
    return $active_levels->{$level} ? 1 : undef;
}

sub errstr { $ERRSTR }

#
# private stuff
#

sub _build_message {
    my $self    = shift;
    my $level   = shift;
    my %message = ();

    if ($self->{prefix}) {
        foreach my $p ( @{$self->{prefixes}} ) {
            $message{message} .= &$p($self, $level, @_);
        }
    }

    if (@_) {
        $message{message} .= join(' ', @_);
    }

    if ($self->{postfix}) {
        foreach my $p ( @{$self->{postfixes}} ) {
            $message{message} .= &$p($self, $level, @_);
        }
    }

    if ($self->{setinfo}) {
        foreach my $p (@{$self->{setinfo}}) {
            my $name = $PLACEHOLDERS{$p}{name};
            my $code = $PLACEHOLDERS{$p}{code};
            $message{$name} = &$code($self, $level);
        }
    }

    if ($self->{debug} || $level eq 'TRACE') {
        $self->_add_trace(\%message);
    } elsif ($self->{newline} && $message{message} =~ /.\z|^\z/) {
        $message{message} .= "\n";
    }

    return \%message;
}

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

sub _set_time {
    my $self = shift;
    my $time = POSIX::strftime($self->{timeformat}, localtime);
    return $time;
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
    return sprintf("%.6f", $cur_time);
}

sub _new_logger {
    my $class   = shift;
    my $type    = shift;
    my $args    = @_ > 1 ? {@_} : shift;
    my $package = ref($type);
    my ($logger, @logger_opts);

    if ( length($package) ) {
        $package .= '::write';
        eval { die "bad package" unless defined &$package };
        if ($@) {
            Carp::croak "the logger must be a blessed referece and provide a write() method";
        }
        push @logger_opts, $args;
        $logger = $type;
    } else {
        push @logger_opts, $class->_shift_options($args);

        if (exists $AVAILABLE_LOGGER{$type}) {
            $package = $AVAILABLE_LOGGER{$type};
        } elsif ($type =~ /::/) {
            $package = $type;
        } else {
            $package = __PACKAGE__ . '::' . ucfirst($type);
        }

        if (!$LOADED_MODULES{$package}) {
            $package->require;
            $LOADED_MODULES{$package} = 1;
        }

        # create a new output object
        $logger = $package->new($args) or Carp::croak $package->errstr;
    }

    my %options = Params::Validate::validate(@logger_opts, {
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
            regex => BOOL_RX,
            default => 0,
        },
        minlevel => {
            type => Params::Validate::SCALAR,
            regex => LEVEL_RX,
            default => 0,
        },
        maxlevel => {
            type => Params::Validate::SCALAR,
            regex => LEVEL_RX,
            default => 4,
        },
        die_on_errors => {
            type => Params::Validate::SCALAR,
            regex => BOOL_RX,
            default => 1,
        },
        debug => {
            type => Params::Validate::SCALAR,
            regex => BOOL_RX,
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
        trace => {
            type => Params::Validate::SCALAR,
            regex => BOOL_RX,
            default => 1,
        },
        setinfo => {
            type => Params::Validate::ARRAYREF,
            default => '',
        },
    });

    foreach my $level (qw/minlevel maxlevel/) {
        if ($options{$level} !~ /^\d\z/) {
            $options{$level} =
                $LEVEL_BY_STRING{ uc($options{$level}) };
        }
    }

    foreach my $level_num ($options{minlevel} .. $options{maxlevel}) {
        my $level = $LEVEL_BY_NUM[ $level_num ];
        $options{active_levels}{$level} = 1;
        next if $level_num > 3;
        $options{active_levels}{FATAL} = 1;
    }

    if ($options{trace}) {
        $options{active_levels}{TRACE} = 1;
    }

    foreach my $o (qw/prefix postfix/) {
        next unless length($options{$o});
        $options{$o} =~ s/<--LEVEL-->/%L/g;
        foreach my $p ( split /%([a-zA-Z])/, $options{$o} ) {
            if ( exists $PLACEHOLDERS{$p} ) {
                push @{$options{"${o}es"}}, $PLACEHOLDERS{$p}{code};
            } else {
                push @{$options{"${o}es"}}, sub { $p };
            }
        }
    }

    if ($options{setinfo}) {
        foreach (@{$options{setinfo}}) {
            s/%//; # replace it
            if ( !exists $PLACEHOLDERS{$_} ) {
                croak "placeholder '$_' does not exists";
            }
        }
    }

    my $self = bless \%options, $class;
    $self->{logger} = $logger;
    return $self;
}

sub _shift_options {
    my ($self, $options) = @_;
    my %logger_opts;

    foreach my $opt (@LOGGER_OPTIONS) {
        next unless exists $options->{$opt};
        $logger_opts{$opt} = delete $options->{$opt};
    }

    return \%logger_opts;
}

sub _raise_error {
    my $self = shift;
    $ERRSTR = shift;
    return undef unless $self->{die_on_errors};
    my $class = ref($self);
    Carp::croak "$class: ".$ERRSTR;
}

1;
