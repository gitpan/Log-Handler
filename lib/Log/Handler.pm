=head1 NAME

Log::Handler - Log messages to one or more outputs.

=head1 SYNOPSIS

    use Log::Handler;

    my $log = Log::Handler->new();

    $log->add(file => {
        filename => 'file.log',
        mode     => 'append',
        maxlevel => 'debug',
        minlevel => 'warning',
        newline  => 1,
    });

    $log->alert("foo bar");

=head1 DESCRIPTION

This module is just a simple object oriented log handler and very easy to use.
It's possible to define a log level for your programs and control the amount
of informations that are logged to one or more outputs.

=head1 LOG LEVELS

There are eigth levels available:

    7   debug
    6   info
    5   notice
    4   warning
    3   error, err
    2   critical, crit
    1   alert
    0   emergency, emerg

C<debug> is the highest and C<emergency> is the lowest level.

=head1 METHODS

=head2 new()

Call C<new()> to create a new log handler object.

    my $log = Log::Handler->new();

=head2 add()

Call C<add()> to add a new output object.

The following options are possible for the handler:

=over 4

=item B<maxlevel> and B<minlevel>

With these options it's possible to set the log levels for your program.

Example:

    maxlevel => 'error'
    minlevel => 'emergency'

    # or

    maxlevel => 'err'
    minlevel => 'emerg'

    # or

    maxlevel => 3
    minlevel => 0

It's possible to set the log level as string or as number. The default setting
for C<maxlevel> is C<warning> and the default setting for C<minlevel> is
C<emergency>.

Example: If C<maxlevel> is set to C<warning> and C<minlevel> to C<emergency>
then the levels C<warning>, C<error>, C<critical>, C<alert> and C<emergency>
would be logged.

You can set both to 8 or C<nothing> if you want to disable the logging machine.

=item B<timeformat>

The C<timeformat> is used for the placeholder C<%T>. You can set C<timeformat>
with a date and time format that is converted with C<POSIX::strftime>. The
default format is S<"%b %d %H:%M:%S"> and looks like

    Feb 01 12:56:31

As example the format S<"%Y/%m/%d %H:%M:%S"> would looks like

    2007/02/01 12:56:31

=item B<dateformat>

The same like C<timeformat>. It's useful if you want to split the date and
time:

    $log->add(file => {
        filename       => 'file.log',
        dateformat     => '%Y-%m-%d',
        timeformat     => '%H:%M:%S',
        message_layout => '%D %T %L %m',
    });

    $log->error("an error here");

Would log

    2007-02-01 12:56:31 ERROR an error here

This option is not used on default.

=item B<newline>

This helpful option appends a newline to the output message if a newline not
exist.

    0 - disable (default)
    1 - enable - appends a newline to the log message if not exist

=item B<message_layout>

With this option you can define your own message layout with different
placeholders in C<printf()> style. The available placeholders are:

    %L   Log level
    %T   Time or full timestamp (option timeformat)
    %D   Date (option dateformat)
    %P   PID
    %H   Hostname
    %N   Newline
    %C   Caller - filename and line number
    %c   Caller - package, filename and line number
    %p   Program name
    %t   Time measurement - replaced with the time since the last call of the handler
    %m   The message.

The default message layout is set to S<"%T [%L] %m">.

As example the following code

    $log->alert("foo bar");

would log

    Feb 01 12:56:31 [ALERT] foo bar

If you set C<message_layout> to

    message_layout => '%T foo %L bar %m (%C)'

and call

    $log->info("baz");

then it would log

    Feb 01 12:56:31 foo INFO bar baz (script.pl, line 40)

Traces will be appended after the complete message.

You can create your own placeholders with the method C<set_pattern()>.

Placeholders are documented in the section L</PLACEHOLDER>.

=item B<message_pattern>

This option is just useful if you want to forward messages with
L<Log::Handler::Output::Forward> or insert the message with
L<Log::Handler::Output::DBI> or dump messages to the screen with
L<Log::Handler::Output::Screen>.

Possible placeholders:

    %L   level
    %T   time
    %D   date
    %P   pid
    %H   hostname
    %N   newline
    %C   caller
    %c   caller
    %p   progname
    %t   mtime
    %m   message

The option expects a array reference with a list of placeholders:

    message_pattern => [ qw/%T %L %H %m/ ]

The patterns are replaced with the pattern names as hash keys and the hash is
passed as reference to the output. Here a full code example:

    use Log::Handler;

    my $log = Log::Handler->new();

    $log->add(forward => {
        forward_to      => \&my_func,
        message_pattern => [ qw/%T %L %H/ ],
        message_layout  => '%m',
        maxlevel        => 'info',
    });

    $log->info('a forwarded message');

    # now you can access it

    sub my_func {
        my $params = shift;
        print "Timestamp: $params->{time}\n";
        print "Level:     $params->{level}\n";
        print "Hostname:  $params->{hostname}\n";
        print "Message:   $params->{message}\n";
    }

=item B<priority>

With this option you can set the priority of your output objects. This means
that messages will be logged at first to the outputs with a higher priority.
If this option is not set then the default priority begins with 10 and will be
increased +1 with each output. Example...

We add a output with no priority

    $log->add(file => { filename => 'file.log' });

This output gets the priority of 10. Now we add another output

    $log->add(file => { filename => 'file.log' });

This output gets the priority of 11... and so on.

Messages would be logged at first to priority 10 and then 11. Now you can add
another output and set the priority to 1.

    $log->add(screen => { dump => 1, priority => 1 });

Messages would be logged now at first to the screen.

=item B<die_on_errors>

Set C<die_on_errors> to 0 if you don't want that the handler die on failed
write operations.

    0 - will not die on errors
    1 - will die (e.g. croak) on errors

If you set C<die_on_errors> to 0 then you have to controll it yourself.

    $log->info('info message') or die $log->errstr();

    # or Log::Handler->errstr()
    # or Log::Handler::errstr()
    # or $Log::Handler::ERRSTR

=item B<filter>

With this option it's possible to define a filter. If the filter is set
than only messages will be logged that match the filter. You can pass a
regexp, a code reference or a simple string. Example:

    $log->add(file => {
        filename => 'file.log',
        mode     => 'append',
        newline  => 1,
        maxlevel => 6,
        filter   => qr/log this/, # log only messages that contain 'log this'
    });

    $log->info('log this');
    $log->info('but not that');

If you pass a code reference then you the message is passed as a hash reference
as first argument. Example:

    $log->add(file => {
        filename => 'file.log',
        mode     => 'append',
        newline  => 1,
        maxlevel => 6,
        filter   => \&my_filter
    });

    sub my_filter {
        my $m = shift;
        $m->{message} =~ /your filter/;
    }

Also it's possible to define a simple condition with matches. You just have
to pass a hash reference with the optione C<matchN> and C<condition>. Example:

    $log->add(file => {
        filename => 'file.log',
        mode     => 'append',
        newline  => 1,
        maxlevel => 6,
        filter   => {
            match1    => 'log this',
            match2    => qr/with that/,
            match3    => '(?:or this|or that)',
            condition => '(match1 && match2) || match3',
        }
    });

NOTE that re-eval in regexes are not valid! Something like

    match1 => '(?{unlink("file.txt")})'

would cause an error.

=item B<alias>

You can set an alias if you want to get the output object later. Example:

    my $log = Log::Handler->new();

    $log->add(screen => {
        maxlevel => 7,
        alias    => 'error',
    });

    my $output_object = $log->get_output('error');

=item B<debug_trace>

You can activate a debugger that writes C<caller()> informations for each log
level that would logged. The debugger is logging all defined values except
C<hints> and C<bitmask>. Set C<debug_trace> to 1 to activate the debugger.
The debugger is set to 0 by default.

=item B<debug_mode>

There are two debug modes: line(1) and block(2) mode. The default mode is 1.

The block mode looks like this:

    use strict;
    use warnings;
    use Log::Handler;

    my $log = Log::Handler->new()

    $log->add(file => {
        filename    => '*STDOUT',
        maxlevel    => 'debug',
        debug_trace => 1,
        debug_mode  => 1
    });

    sub test1 { $log->warning() }
    sub test2 { &test1; }

    &test2;

Output:

    Apr 26 12:54:11 [WARN] 
       CALL(4): package(main) filename(./trace.pl) line(15) subroutine(main::test2) hasargs(0)
       CALL(3): package(main) filename(./trace.pl) line(13) subroutine(main::test1) hasargs(0)
       CALL(2): package(main) filename(./trace.pl) line(12) subroutine(Log::Handler::__ANON__) hasargs(1)
       CALL(1): package(Log::Handler) filename(/usr/local/share/perl/5.8.8/Log/Handler.pm) line(713) subroutine(Log::Handler::_write) hasargs(1)
       CALL(0): package(Log::Handler) filename(/usr/local/share/perl/5.8.8/Log/Handler.pm) line(1022) subroutine(Devel::Backtrace::new) hasargs(1) wantarray(0)

The same code example but the debugger in block mode would looks like this:

       debug_mode => 2

Output:

   Apr 26 12:52:17 [DEBUG] 
      CALL(4):
         package     main
         filename    ./trace.pl
         line        15
         subroutine  main::test2
         hasargs     0
      CALL(3):
         package     main
         filename    ./trace.pl
         line        13
         subroutine  main::test1
         hasargs     0
      CALL(2):
         package     main
         filename    ./trace.pl
         line        12
         subroutine  Log::Handler::__ANON__
         hasargs     1
      CALL(1):
         package     Log::Handler
         filename    /usr/local/share/perl/5.8.8/Log/Handler.pm
         line        681
         subroutine  Log::Handler::_write
         hasargs     1
      CALL(0):
         package     Log::Handler
         filename    /usr/local/share/perl/5.8.8/Log/Handler.pm
         line        990
         subroutine  Devel::Backtrace::new
         hasargs     1
         wantarray   0

=item B<debug_skip>

This option let skip the C<caller()> informations the count of C<debug_skip>.

    debug_skip => 2

    Apr 26 12:55:07 [DEBUG] 
       CALL(2): package(main) filename(./trace.pl) line(16) subroutine(main::test2) hasargs(0)
       CALL(1): package(main) filename(./trace.pl) line(14) subroutine(main::test1) hasargs(0)
       CALL(0): package(main) filename(./trace.pl) line(13) subroutine(Log::Handler::__ANON__) hasargs(1)

=back

=head2 How to use add()

The method C<add()> excepts 2 option parts; the options for the handler and
for the output module you want to use - the output modules got it's own
documentation for all options.

There are different ways to add a new output to the handler. The one way is
that you create the output object yourself and pass it with the handler options
to C<add()>.

Example:

    use Log::Handler;
    use Log::Handler::Output::File;

    # the handler options - how to handle the output
    my %handler_options = (
        timeformat      => '%Y/%m/%d %H:%M:%S',
        newline         => 1,
        message_layout  => '%T [%L] %p: %m',
        maxlevel        => 'debug',
        minlevel        => 'emergency',
        die_on_errors   => 1,
        debug_trace     => 0,
        debug_mode      => 2,
        debug_skip      => 0,
    );

    # the file options - how to handle the file
    my %file_options = (
        filename        => 'file.log',
        filelock        => 1,
        fileopen        => 1,
        reopen          => 1,
        mode            => 'append',
        autoflush       => 1,
        permissions     => '0660',
        utf8            => 1,
    );

    # we creating the file object
    my $file = Log::Handler::Output::File->new( \%file_options );

    # creating a new handler object
    my $log = Log::Handler->new();

    # now we add the file object to the handler with the handler options
    $log->add( $file => \%handler_options );

But it can be simplier! You can merge all options and pass them to C<add()>
in one step, you just need to tell the handler what do you want to add.

    # merge the options
    my %all_options = (%output_options, %file_options);

    # pass all options and say what you want to add -> a file!
    $log->add( file => \%all_options );

The options will be splitted intern and you don't need to split it yourself,
only if you want to do it yourself.

Further examples:

    $log->add( email   => \%all_options );
    $log->add( forward => \%all_options );
    # and so on ...

Take a look to the section L</EXAMPLES> for more informations.

=head2 Log level methods

=over 4

=item B<debug()>

=item B<info()>

=item B<notice()>

=item B<warning()>

=item B<error()>, B<err()>

=item B<critical()>, B<crit()>

=item B<alert()>

=item B<emergency()>, B<emerg()>

=back

The call of a log level method is very simple:

    $log->info("Hello World! How are you?");

Or maybe:

    $log->info("Hello World!", "How are you?");

Both calls would log - if the level INFO is active:

    Feb 01 12:56:31 [INFO] Hello World! How are you?

=head2 is_* methods

=over 4

=item B<is_debug()>

=item B<is_info()>

=item B<is_notice()>

=item B<is_warning()>

=item B<is_error()>, B<is_err()>

=item B<is_critical()>, B<is_crit()>

=item B<is_alert()>

=item B<is_emergency()>, B<is_emerg()>

=back

These thirteen methods could be very useful if you want to kwow if the current
log level would output the message. All methods returns TRUE if the current set
of C<minlevel> and C<maxlevel> would log the message and FALSE if not. Example:

    $log->debug(Dumper(\%hash));

This example would dump the hash in any case and pass it to the log handler, 
but that is not that what we really want!

    if ( $log->is_debug ) {
        $log->debug(Dumper(\%hash));
    }

Now we dump the hash only if the current log level would log it.

The methods C<is_err()>, C<is_crit()> and C<is_emerg()> are just shortcuts.

=head2 Other level methods

There exists a lot of other level methods.

For a full list take a look into the documentation of L<Log::Handler::Levels>.

=head2 get_output()

Call C<get_output($alias)> to get the output object that you added with 
the option C<alias>.

=head2 errstr()

Call C<errstr()> if you want to get the last error message. This is useful
with C<die_on_errors>. If you set C<die_on_errors> to C<0> the handler wouldn't
croak on failed write operations. Set C<die_on_errors> to control it yourself.

    use Log::Handler;

    my $log = Log::Handler->new();

    $log->add(file => {
        filename      => 'file.log',
        maxlevel      => 'info',
        mode          => 'append',
        die_on_errors => 0,
    });

    $log->info("Hello World!") or die $log->errstr;

Or

    unless ( $log->info("Hello World!") ) {
        $error_string = $log->errstr;
        # do something with $error_string
    }

The exception is that the handler croaks in any case if the call of C<new()> or
C<add()> fails because on missing or wrong settings!

=head2 config()

With this method it's possible to load your output configuration from a file.

    $log->config(filename => 'file.conf');

Or

    $log->config(config => {
        file => {
            default => {
                newline       => 1,
                debug_mode    => 2,
                die_on_errors => 0
            },
            error_log => {
                filename      => 'error.log',
                maxlevel      => 'warning',
                minlevel      => 'emerg',
                priority      => 1
            },
            common_log => {
                filename      => 'common.log',
                maxlevel      => 'info',
                minlevel      => 'emerg',
                priority      => 2
            },
        }
    });

The default section - I call it section here - can be used to define default
parameters for all file outputs.

Take a look into the documentation of L<Log::Handler::Config> for more
informations.

=head2 set_pattern()

With this option you can set your own placeholders. Example:

    $log->set_pattern('%X', 'name', sub { });

    # or

    $log->set_pattern('%X', 'name', 'value');

Then you can use this pattern in your message layout:

    $log->add(forward => {
        filename        => 'file.log',
        message_layout  => '%X %m',
    });

=head1 EXAMPLES

L<Log::Handler::Examples>

=head1 EXTENSIONS

Start it or write me a mail if you have questions.

=head1 PREREQUISITES

Prerequisites for all modules:

    Carp
    Data::Dumper
    Devel::Backtrace
    Fcntl
    Net::SMTP
    Params::Validate
    POSIX
    Time::HiRes
    Sys::Hostname
    UNIVERSAL::require

And maybe for the config loader:

    Config::General
    Config::Properties
    YAML

Just for the test suite:

    File::Spec
    Test::More

=head1 EXPORTS

No exports.

=head1 REPORT BUGS

Please report all bugs to <jschulz.cpan(at)bloonix.de>.

=head1 AUTHOR

Jonny Schulz <jschulz.cpan(at)bloonix.de>.

=head1 QUESTIONS

Do you have any questions or ideas?

MAIL: <jschulz.cpan(at)bloonix.de>

IRC: irc.perl.org#perl

If you send me a mail then add Log::Handler into the subject.

=head1 TODO

Maybe; don't know

    * Log::Handler::Filter

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

package Log::Handler;

use strict;
use warnings;
use Carp;
use POSIX;
use Params::Validate;
use UNIVERSAL::require;
use Log::Handler::Output;
use Log::Handler::Config;
use Log::Handler::Pattern;
use base qw(Log::Handler::Levels);

our $VERSION  = '0.39_16';
our $ERRSTR   = '';
our $PRIORITY = 10;
our $DEBUG    = 0;

# to convert minlevel and maxlevel
my %LEVEL_BY_STRING = ( 
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
    FATAL     =>  0,
);

# to iterate from minlevel to maxlevel
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

our %AVAILABLE_OUTPUTS = (
    file    => 'Log::Handler::Output::File',
    email   => 'Log::Handler::Output::Email',
    forward => 'Log::Handler::Output::Forward',
    dbi     => 'Log::Handler::Output::DBI',
    screen  => 'Log::Handler::Output::Screen',
    socket  => 'Log::Handler::Output::Socket',
);

# this is needed to validate different options
use constant BOOL_RX => qr/^[01]\z/;

# this is needed to validate minlevel and maxlevel
use constant LEVEL_RX => qr/^(?:
    8 | nothing   |
    7 | debug     |
    6 | info      |
    5 | notice    |
    4 | warning   |
    3 | error     | err  |
    2 | critical  | crit |
    1 | alert     |
    0 | emergency | emerg |
    fatal
)\z/x;

sub new {
    my $class = shift;

    # for full backward compatibilities
    if (@_) {
        require Log::Handler::Simple;
        return  Log::Handler::Simple->new(@_);
    }

    my $self = bless {
        pattern    => &Log::Handler::Pattern::get_pattern,
        priorities => { },
        levels     => { },
        alias      => { },
    }, $class;

    return $self;
}

sub add {
    my $self   = shift;
    my $output = $self->_new_output(@_);
    my $levels = $self->{levels};

    foreach my $level (keys %{$output->{levels}}) {
        if ($levels->{$level}) {
            my @old_order = @{$levels->{$level}};
            push @old_order, $output;
            $levels->{$level} = [
                map  { $_->[0] }
                sort { $a->[1] <=> $b->[1] }
                map  { [ $_, $_->{priority} ] } @old_order
            ];
        } else {
            push @{$levels->{$level}}, $output;
        }
    }

    if ($output->{alias}) {
        my $alias = $output->{alias};
        $self->{alias}->{$alias} = $output;
    }

    return 1;
}

sub config {
    my $self = shift;
    my $configs = Log::Handler::Config->config(@_);

    while ( my ($type, $config) = each %$configs ) {
        for my $c (@$config) {
            $self->add($type, $c);
        }
    }

    return 1;
}

sub set_pattern {
    @_ == 4 or Carp::croak 'Usage: $log->set_pattern( $pattern, $name, $code )';
    my ($self, $pattern, $name, $proto) = @_;

    if ($pattern !~ /^%[a-zA-Z]\z/) {
        Carp::croak "'$pattern' is not a valid pattern";
    }

    if (ref($name) || !length($name)) {
        Carp::croak "not a valid name for pattern '$pattern'";
    }

    if (ref($proto) eq 'CODE') {
        $self->{pattern}->{$pattern}->{code} = $proto;
    } elsif (length($proto)) {
        $self->{pattern}->{$pattern}->{code} = $proto;
    }

    $self->{pattern}->{$pattern}->{name} = $name;
}

sub get_output {
    my ($self, $name) = @_;
    return unless length($name);
    my $alias = $self->{alias};
    return $alias->{$name};
}

sub errstr { $ERRSTR }

#
# private stuff
#

sub _shift_options {
    my ($self, $options) = @_;
    my %output_opts;

    my @output_options = qw(
        timeformat
        message_layout
        message_pattern
        prepare_message
        newline
        minlevel
        maxlevel
        die_on_errors
        priority
        debug_trace
        debug_mode
        debug_skip
        alias
        filter
    );

    foreach my $opt ( @output_options ) {
        next unless exists $options->{$opt};
        $output_opts{$opt} = delete $options->{$opt};
    }

    return \%output_opts;
}

sub _new_output {
    my $self    = shift;
    my $type    = shift;
    my $args    = @_ > 1 ? {@_} : shift;
    my $package = ref($type);
    my ($output, $options);

    if ( length($package) ) {
        $output  = $type;
        $options = $args;
    } else {
        # shift the handler options from $args. the rest in $args
        # is for the output module
        $options = $self->_shift_options($args);

        if (exists $AVAILABLE_OUTPUTS{$type}) {
            $package = $AVAILABLE_OUTPUTS{$type};
        } elsif ($type =~ /::/) {
            $package = $type;
        } else {
            $package = 'Log::Handler::Output::' . ucfirst($type);
        }

        # load the necessary output. require() knows what modules
        # are loaded so I don't need to check this
        $package->require;

        # create a new output object and pass $args
        $output = $package->new($args) or Carp::croak $package->errstr;
    }

    $options = $self->_validate_options($options);
    $options->{output} = $output;
    return Log::Handler::Output->new($options);
}

sub _validate_options {
    my $self     = shift;
    my $pattern  = $self->{pattern};
    my $is_fatal = ();

    my %options = Params::Validate::validate(@_, {
        timeformat => {
            type => Params::Validate::SCALAR,
            default => '%b %d %H:%M:%S',
        },
        dateformat => {
            type => Params::Validate::SCALAR,
            default => '%b %d %Y',
        },
        message_layout => {
            type => Params::Validate::SCALAR,
            default => '%T [%L] %m',
        },
        message_pattern => {
            type => Params::Validate::SCALAR | Params::Validate::ARRAYREF,
            optional => 1,
        },
        prepare_message => {
            type => Params::Validate::CODEREF,
            optional => 1,
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
        priority => {
            type => Params::Validate::SCALAR,
            regex => qr/^\d+\z/,
            default => undef,
        },
        debug_trace => {
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
        alias => {
            type => Params::Validate::SCALAR,
            optional => 1,
        },
        filter => {
            type => Params::Validate::SCALAR    # 'foo'
                  | Params::Validate::SCALARREF # qr/foo/
                  | Params::Validate::CODEREF   # sub { shift->{message} =~ /foo/ }
                  | Params::Validate::HASHREF,  # matchN, condition
            optional => 1,
        },
    });

    if ($options{filter}) {
        $options{filter} = $self->_validate_filter($options{filter});
    }

    if (!defined $options{priority}) {
        $options{priority} = $PRIORITY++;
    }

    foreach my $opt (qw/minlevel maxlevel/) {
        next if $options{$opt} =~ /^\d\z/;
        my $level = uc($options{$opt});
        $options{$opt} = $LEVEL_BY_STRING{$level};
    }

    foreach my $level_num ($options{minlevel} .. $options{maxlevel}) {
        my $level = $LEVEL_BY_NUM[ $level_num ];
        $options{levels}{$level} = 1;
        next if $is_fatal || $level_num > 3;
        $options{levels}{FATAL} = 1;
    }

    foreach my $p ( split /(%[a-zA-Z])/, $options{message_layout} ) {
        if ( exists $pattern->{$p} ) {
            push @{$options{message_order}}, $pattern->{$p}{code};
        } else {
            push @{$options{message_order}}, $p;
        }
    }

    if ($options{message_pattern}) {
        my @pattern = ();
        if (!ref($options{message_pattern})) {
            $options{message_pattern} = [ split /\s+/, $options{message_pattern} ];
        }
        foreach (@{$options{message_pattern}}) {
            if ( !exists $pattern->{$_} ) {
                croak "placeholder '$_' does not exists";
            } elsif ( $_ eq '%m' ) {
                next; # %m is default
            }
            my $name = $pattern->{$_}->{name};
            my $code = $pattern->{$_}->{code};
            $options{pattern}{$name} = $code;
        }
    }

    return \%options;
}

sub _validate_filter {
    my ($self, $args) = @_;
    my $ref = ref($args);
    my %filter;

    if ($ref eq 'CODE') {
        $filter{code} = $args;
    } elsif ($ref eq 'Regexp') {
        $filter{code} = sub { shift->{message} =~ $args };
    } elsif (!$ref) {
        $filter{code} = sub { shift->{message} =~ /$args/ };
    } else {
        %filter = %$args;

        if (!defined $filter{condition} || $filter{condition} !~ /\w/) {
            Carp::croak "missing condition for paramater 'filter'";
        }

        my $cond = $filter{condition};
        $cond =~ s/match\d+//g;
        $cond =~ s/[()&|!<>=\s\d]+//;

        if ($cond) {
            Carp::croak "invalid characters in condition: '$cond'";
        }

        foreach my $m ($filter{condition} =~ /(match\d+)/g) {
            if (!exists $filter{$m}) {
                Carp::croak "missing regexp for $m";
            }
            $ref = ref($filter{$m});
            if (!$ref) {
                $filter{$m} = qr/$filter{$m}/;
            } elsif ($ref ne 'Regexp') {
                Carp::croak "invalid value for option 'filter:$m'";
            }
            $filter{result}{$m} = '';
        }

        $filter{codestring}  =  "sub { my \$m = shift; ";
        #$filter{codestring} .=  "use Data::Dumper; warn Dumper(\$m); ";
        $filter{codestring} .=  "$filter{condition}; }";
        $filter{codestring}  =~ s/(match\d+)/\$m->{$1}/g;
        $filter{code} = eval $filter{codestring};
    }

    return \%filter;
}

sub _raise_error {
    my $self = shift;
    $ERRSTR = shift;
    return undef;
}

1;
