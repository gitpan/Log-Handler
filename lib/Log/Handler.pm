=head1 NAME

Log::Handler - Log messages to several outputs.

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

    $log->warning("a warinng here");

=head1 DESCRIPTION

The C<Log::Handler> is a object oriented handler for logging, tracing and
debugging. It is very easy to use and provides a simple interface for
multiple output objects with lots of configuration parameters. You can
easily filter the amount of logged information on a per-output base,
define priorities and create patterns to format the messages.

See the documentation for details.

=head1 LOG LEVELS

There are eigth levels available:

    7   debug
    6   info
    5   notice
    4   warning, warn
    3   error, err
    2   critical, crit
    1   alert
    0   emergency, emerg

C<debug> is the highest and C<emergency> is the lowest level.

Level C<debug> is the highest level because it basically says to log
every peep.

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

The option C<timeformat> is used to set the format for the placeholder C<%T>.
The string is converted with C<POSIX::strftime>. The default format is set to
S<"%b %d %H:%M:%S"> and looks like

    Feb 01 12:56:31

If you would set the format to S<"%Y/%m/%d %H:%M:%S"> it would looks like

    2007/02/01 12:56:31

=item B<dateformat>

This options works like C<timeformat>. You can set a format that is used for
the placeholder C<%D>. It's just useful if you want to split the date and time:

    $log->add(file => {
        filename       => 'file.log',
        dateformat     => '%Y-%m-%d',
        timeformat     => '%H:%M:%S',
        message_layout => '%D %T %L %m',
    });

    $log->error("an error here");

This looks like

    2007-02-01 12:56:31 ERROR an error here

This option is not used by default.

=item B<newline>

This helpful option appends a newline to the message if a newline not exist.

    0 - do nothing (default)
    1 - append a newline if not exist

=item B<message_layout>

With this option it's possible to create your own message layout with different
placeholders in C<printf()> style. The available placeholders are:

    %L   Log level
    %T   Time or full timestamp (option timeformat)
    %D   Date (option dateformat)
    %P   PID
    %H   Hostname
    %N   Newline
    %S   Program name
    %C   Caller - filename and line number
    %p   Caller - package name
    %f   Caller - file name
    %l   Caller - line number
    %s   Caller - subroutine name
    %r   Runtime in seconds since program start
    %t   Time measurement - replaced with the time since the last call of $level
    %m   Message
    %%   Procent

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

=item B<message_pattern>

This option is just useful if you want to forward messages to output
modules that needs the parts of a message as a hash reference - as
example L<Log::Handler::Output::Forward>, L<Log::Handler::Output::DBI>
or L<Log::Handler::Output::Screen>.

The option expects a list of placeholders:

    # as a array reference
    message_pattern => [ qw/%T %L %H %m/ ]

    # or as a string
    message_pattern => '%T %L %H %m'
 
The patterns will be replaced with real names as hash keys.

    %L   level
    %T   time
    %D   date
    %P   pid
    %H   hostname
    %N   newline
    %r   runtime
    %C   caller
    %p   package
    %f   filename
    %l   line
    %s   subroutine
    %S   progname
    %t   mtime
    %m   message

Here a full code example:

    use Log::Handler;

    my $log = Log::Handler->new();

    $log->add(forward => {
        forward_to      => \&my_func,
        message_pattern => [ qw/%T %L %H %m/ ],
        message_layout  => '%m',
        maxlevel        => 'info',
    });

    $log->info('a forwarded message');

    # now you can access it

    sub my_func {
        my $msg = shift;
        print "Timestamp: $msg->{time}\n";
        print "Level:     $msg->{level}\n";
        print "Hostname:  $msg->{hostname}\n";
        print "Message:   $msg->{message}\n";
    }

=item B<priority>

With this option you can set the priority of your output objects. This means
that messages will be logged at first to the outputs with a higher priority.
If this option is not set then the default priority begins with 10 and will be
increased +1 with each output. Example:

We add a output with no priority

    $log->add(file => { filename => 'file.log' });

This output gets the priority of 10. Now we add another output

    $log->add(file => { filename => 'file.log' });

This output gets the priority of 11... and so on.

Messages would be logged at first to the output with the priority of 10 and to
the output with the priority of 11. Now you can add another output and set the
priority to 1.

    $log->add(screen => { dump => 1, priority => 1 });

Messages would be logged now at first to the screen.

=item B<die_on_errors>

Set C<die_on_errors> to 0 if you don't want that the handler dies on failed
write operations.

    0 - to disable it
    1 - to enable it

If you set C<die_on_errors> to 0 then you have to controll it yourself.

    $log->info('info message') or die $log->errstr();

    # or Log::Handler->errstr()
    # or Log::Handler::errstr()
    # or $Log::Handler::ERRSTR

=item B<filter>

With this option it's possible to set a filter. If the filter is set then
only messages will be logged that match the filter. You can pass a regexp,
a code reference or a simple string. Example:

    $log->add(file => {
        filename => 'file.log',
        mode     => 'append',
        newline  => 1,
        maxlevel => 6,
        filter   => qr/log this/, # log only messages that contain 'log this'
    });

    $log->info('log this');
    $log->info('but not that');

If you pass your own code then you have to check the message yourself.

    $log->add(file => {
        filename => 'file.log',
        mode     => 'append',
        newline  => 1,
        maxlevel => 6,
        filter   => \&my_filter
    });

    # return TRUE if you want to log the message, FALSE if not
    sub my_filter {
        my $msg = shift;
        $msg->{message} =~ /your filter/;
    }

It's also possible to define a simple condition with matches. Just pass a
hash reference with the options C<matchN> and C<condition>. Example:

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

NOTE that re-eval in regexes is not valid! Something like

    match1 => '(?{unlink("file.txt")})'

would cause an error!

=item B<alias>

You can set an alias if you want to get the output object later. Example:

    my $log = Log::Handler->new();

    $log->add(screen => {
        maxlevel => 7,
        alias    => 'screen-out',
    });

    my $screen = $log->output('screen-out');

    $screen->log(message => 'foo');

    # or in one step

    $log->output('screen-out')->log(message => 'foo');

=item B<debug_trace>

You can activate a debugger that writes C<caller()> informations for each
active log level. The debugger is logging all defined values except C<hints>
and C<bitmask>. Set C<debug_trace> to 1 to activate the debugger.
The debugger is set to 0 by default.

=item B<debug_mode>

There are two debug modes: line(1) and block(2) mode. The default mode is 1.

The line mode looks like this:

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

    Apr 26 12:54:11 [WARNING] 
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

=back

=head2 HowTo use add()

The method C<add()> excepts 2 parts of options; the options for the handler and
the options for the output module you want to use. The output modules got it's own
documentation for all options. As example if you want to add a file-output then
take a look into the documentation of L<Log::Handler::Output::File> to see which
options are available.

There are different ways to add a new output to the handler. One way is to create
the output object yourself and pass it with the handler options to C<add()>.

Example:

    use Log::Handler;
    use Log::Handler::Output::File;

    # the handler options - how to handle the output
    my %handler_options = (
        timeformat      => '%Y/%m/%d %H:%M:%S',
        newline         => 1,
        message_layout  => '%T [%L] %S: %m',
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

    # create the file object
    my $file = Log::Handler::Output::File->new( \%file_options );

    # create a new handler object
    my $log = Log::Handler->new();

    # now we add the file object to the handler with the handler options
    $log->add( $file => \%handler_options );

But it can be simplier! You can merge all options and pass them to C<add()>
in one step, you just need to tell the handler what do you want to add.

    use Log::Handler;

    my $log = Log::Handler->new();

    $log->add(

        # what do you want to add - a file output
        file => {

            # handler options
            timeformat      => '%Y/%m/%d %H:%M:%S',
            newline         => 1,
            message_layout  => '%T [%L] %S: %m',
            maxlevel        => 'debug',
            minlevel        => 'emergency',
            die_on_errors   => 1,
            debug_trace     => 0,
            debug_mode      => 2,
            debug_skip      => 0,

            # file options
            filename        => 'file.log',
            filelock        => 1,
            fileopen        => 1,
            reopen          => 1,
            mode            => 'append',
            autoflush       => 1,
            permissions     => '0660',
            utf8            => 1,

        }
    );

The options will be splitted internal and you don't need to split it yourself,
only if you want to do it yourself.

Take a look to L<Log::Handler::Examples> for more informations.

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

Both calls would log - if level INFO is active:

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
level would log the message. All methods returns TRUE if the current set
of C<minlevel> and C<maxlevel> would log the message and FALSE if not.

=head2 Other level methods

There exists some other level methods.

For a full list take a look into the documentation of L<Log::Handler::Levels>.

=head2 output()

Call C<output($alias)> to get the output object that you added with 
the option C<alias>.

It's possible to access a output directly:

    $log->output($alias)->log(message => 'booo');

For more informations take a look to the option C<alias>.

=head2 flush()

Call C<flush()> if you want to send flush to all outputs that can flush.

Flush means to flush buffers and/or close and re-open outputs.

If you want to send it only to some outputs you can pass the aliases.

    $log->flush(); # flush all
    $log->flush('foo', 'bar'); # flush only foo and bar

If option S<"die_on_errors"> is set to 0 then you can intercept errors with:

    $log->flush or die $log->errstr;

=head2 errstr()

Call C<errstr()> if you want to get the last error message. This is useful
if you set C<die_on_errors> to C<0> and the handler wouldn't die on failed
write operations.

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

The exception is that the handler dies in any case if the call of C<new()> or
C<add()> fails because on missing or wrong settings!

=head2 config()

With this method it's possible to load your output configuration from a file.

    $log->config(config => 'file.conf');

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

The key S<"default"> is used here to define default parameters for all file
outputs. All other keys (C<error_log>, C<common_log>) are used as aliases.

Take a look into the documentation of L<Log::Handler::Config> for more
informations.

=head2 set_pattern()

With this option you can set your own placeholders. Example:

    $log->set_pattern('%X', 'key_name', sub { 'value' });

    # or

    $log->set_pattern('%X', 'key_name', 'value');

Then you can use this pattern in your message layout:

    $log->add(file => {
        filename        => 'file.log',
        mode            => 'append',
        message_layout  => '%X %m %N',
    });

Or use it with C<message_pattern>:

    sub func {
        my $m = shift;
        print "$m->{key_name} $m->{message}\n";
    }

    $log->add(forward => {
        forward_to      => \&func,
        message_pattern => '%X %m',
    });

Note: valid character for the key name are: C<[%\w\-\.]+>

=head1 EXAMPLES

L<Log::Handler::Examples>

=head1 EXTENSIONS

Send me a mail if you have questions.

=head1 PREREQUISITES

Prerequisites for all modules:

    Perl 5.6.1
    Carp
    Data::Dumper
    Devel::Backtrace
    Fcntl
    Params::Validate
    POSIX
    Time::HiRes
    Sys::Hostname
    UNIVERSAL::require

Recommended modules:

    Config::General
    Config::Properties
    DBI
    IO::Socket
    Net::SMTP
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
use Params::Validate;
use UNIVERSAL::require;
use Log::Handler::Output;
use Log::Handler::Config;
use Log::Handler::Pattern;
use base qw(Log::Handler::Levels);

our $VERSION = '0.44';
our $ERRSTR  = '';

# turn on/off tracing
our $TRACE = 0;

use constant PRIORITY => 10;
use constant BOOL_RX  => qr/^[01]\z/;
use constant NUMB_RX  => qr/^\d+\z/;
use constant LEVEL_RX => qr/^(?:
    8 | nothing   |
    7 | debug     |
    6 | info      |
    5 | notice    |
    4 | warning   | warn  |
    3 | error     | err   |
    2 | critical  | crit  |
    1 | alert     |
    0 | emergency | emerg |
        fatal
)\z/x;

# to convert minlevel and maxlevel to a number
our %LEVEL_BY_STRING = ( 
    DEBUG     =>  7,  
    INFO      =>  6,  
    NOTICE    =>  5,  
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

# to iterate from minlevel to maxlevel and
# create an HoA with all active levels
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

# shortcuts for each output
our %AVAILABLE_OUTPUTS = (
    file    => 'Log::Handler::Output::File',
    email   => 'Log::Handler::Output::Email',
    forward => 'Log::Handler::Output::Forward',
    dbi     => 'Log::Handler::Output::DBI',
    screen  => 'Log::Handler::Output::Screen',
    socket  => 'Log::Handler::Output::Socket',
);

sub new {
    my $class = shift;

    # for full backward compatibilities to v0.38
    if (@_) {
        require Log::Handler::Simple;
        return  Log::Handler::Simple->new(@_);
    }

    my $self = bless {
        priority => PRIORITY,   # start priority
        levels   => { },        # outputs stored by active levels
        alias    => { },        # outputs stored by an alias
        output   => [ ],        # all outputs needed for flush()
        pattern  =>             # default pattern
            &Log::Handler::Pattern::get_pattern,
    }, $class;

    return $self;
}

sub add {
    @_ == 3 or Carp::croak 'Usage: $log->add( $output => \%options )';
    my $self   = shift;
    my $output = $self->_new_output(@_);
    my $levels = $self->{levels};

    # Structure:
    #   $self->{levels}->{INFO} = [ outputs ordered by priority ]
    #
    # All outputs that would log the level INFO will be stored to the
    # hash-tree $self->{levels}->{INFO}. On this way it's possible
    # to check very fast if the level is active
    #
    #   my $levels = $self->{levels};
    #   if (exists $levels->{INFO}) { ... }
    #
    # and loop over all output objects and pass the message to it.

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

    # Structure:
    #   $self->{alias}->{$alias} = $output_object
    #
    # All outputs with an alias are stored to this hash tree.
    # Each output can be fetched with output($alias);

    if ($output->{alias}) {
        my $alias = $output->{alias};
        $self->{alias}->{$alias} = $output;
    }

    # save all outputs here
    push @{$self->{outputs}}, $output;

    return 1;
}

sub config {
    @_ > 1 or Carp::croak 'Usage: $log->config( %param )';
    my $self = shift;
    my $configs = Log::Handler::Config->config(@_);

    # Structure:
    #   $configs->{file} = [ output configs ];
    #   $configs->{dbi}  = [ output configs ];

    while ( my ($type, $config) = each %$configs ) {
        for my $c (@$config) {
            $self->add($type, $c);
        }
    }

    return 1;
}

sub set_pattern {
    (@_ == 3 || @_ == 4)
        or Carp::croak 'Usage: $log->set_pattern( $pattern, $name, $code )';

    my $self    = shift;
    my $pattern = shift;

    # If no $name is set then we use $pattern as name
    my ($name, $proto) = @_ == 2 ? @_ : ($pattern, @_);

    if ($pattern !~ /^%[a-ln-z]\z/i) {
        Carp::croak "invalid pattern '$pattern'";
    }

    if (!defined $name || $name !~ /^[%\w\-\.]+\z/) {
        Carp::croak "invalid/missing name for pattern '$pattern'";
    }

    # Structure:
    #   $self->{pattern}->{'%X'}->{name} = 'name-of-x';
    #   $self->{pattern}->{'%X'}->{code} = 'value-of-x';
    $self->{pattern}->{$pattern}->{code} = $proto;
    $self->{pattern}->{$pattern}->{name} = $name;
}

sub output {
    @_ == 2 or Carp::croak 'Usage: $log->output( $alias )';
    my ($self, $name) = @_;
    my $alias = $self->{alias};
    return exists $alias->{$name} ? $alias->{$name}->{output} : undef;
}

sub flush {
    my ($self, @alias) = @_;
    my $errors = ();

    if (@alias) {
        foreach my $name (@alias) {
            my $output = $self->output($name);
            next unless $output;
            if ( !$output->flush ) {
                if ( defined $errors ) {
                    $errors .= '; ' . $output->errstr;
                } else {
                    $errors = $output->errstr;
                }
            }
        }
    } else {
        foreach my $output (@{$self->{outputs}}) {
            if ( !$output->flush ) {
                if ( defined $errors ) {
                    $errors .= '; ' . $output->errstr;
                } else {
                    $errors = $output->errstr;
                }
            }
        }
    }

    return defined $errors ? $self->_raise_error($errors) : 1;
}

sub errstr { $ERRSTR }

#
# private stuff
#

sub _shift_options {
    my ($self, $output_opts) = @_;
    my %handler_opts;

    # It's possible to pass all options for the handler and for the
    # output to add(). These options must be splitted. The options
    # for the handler will be passed to Log::Handler::Output. The
    # options for the output will be passed - as example - to
    # Log::Handler::Output::File.

    my @shift_options = qw(
        alias
        debug_mode
        debug_skip
        debug_trace
        die_on_errors
        filter
        maxlevel
        message_layout
        message_pattern
        minlevel
        newline
        prepare_message
        priority
        timeformat
    );

    foreach my $opt ( @shift_options ) {
        next unless exists $output_opts->{$opt};
        $handler_opts{$opt} = delete $output_opts->{$opt};
    }

    return \%handler_opts;
}

sub _new_output {
    my $self    = shift;
    my $type    = shift;
    my $args    = @_ > 1 ? {@_} : shift;
    my $package = ref($type);
    my ($output, $handler_opts);

    # There are two ways to add an output:
    #
    #   my $log  = Log::Handler->new();
    #   my $file = Log::Handler::Output::File->new(\%output_opts);
    #   $log->add($file => \%handler_opts);
    #
    # and
    #
    #   my $log = Log::Handler->new();
    #   $log->add(file => \%all_options);

    if ( length($package) ) {
        $output = $type;
        $handler_opts = $args;
    } else {
        # Shift the handler options from $args. The rest in %$args
        # will be passed to the output.
        $handler_opts = $self->_shift_options($args);

        # Try to determine which output is wanted...
        if (exists $AVAILABLE_OUTPUTS{$type}) {
            $package = $AVAILABLE_OUTPUTS{$type};
        } elsif ($type =~ /::/) {
            $package = $type;
        } else {
            $package = 'Log::Handler::Output::' . ucfirst($type);
        }

        $package->require;
        $output = $package->new($args) or Carp::croak $package->errstr;
    }

    $handler_opts = $self->_validate_options($handler_opts);
    return Log::Handler::Output->new($handler_opts, $output);
}

sub _validate_options {
    my $self    = shift;
    my $pattern = $self->{pattern};
    my (%wanted, $is_fatal);

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
            type => Params::Validate::SCALAR
                  | Params::Validate::ARRAYREF,
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
            regex => NUMB_RX,
            default => undef,
        },
        debug_trace => {
            type => Params::Validate::SCALAR,
            regex => BOOL_RX,
            default => 0,
        },
        debug_mode => {
            type => Params::Validate::SCALAR,
            regex => NUMB_RX,
            default => 1,
        },
        debug_skip => {
            type => Params::Validate::SCALAR,
            regex => NUMB_RX,
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
        caller_level => {
            type => Params::Validate::SCALAR,
            regex => NUMB_RX,
            default => 2,
        },
    });

    if ($options{filter}) {
        $options{filter} = $self->_validate_filter($options{filter});
    }

    # set a default priority if not set
    if (!defined $options{priority}) {
        $options{priority} = $self->{priority}++;
    }

    # replace the level strings with numbers
    foreach my $opt (qw/minlevel maxlevel/) {
        next if $options{$opt} =~ /^\d\z/;
        my $level = uc($options{$opt});
        $options{$opt} = $LEVEL_BY_STRING{$level};
    }

    # iterate from minlevel to maxlevel and create
    # a hash tree with all active levels
    foreach my $level_num ($options{minlevel} .. $options{maxlevel}) {
        my $level = $LEVEL_BY_NUM[ $level_num ];
        $options{levels}{$level} = 1;
        next if $is_fatal || $level_num > 3;
        $options{levels}{FATAL} = 1;
    }

    if ($options{message_pattern}) {
        if (!ref($options{message_pattern})) {
            $options{message_pattern} = [ split /\s+/, $options{message_pattern} ];
        }
        foreach my $p (@{$options{message_pattern}}) {
            if (!exists $pattern->{$p}) {
                Carp::croak "undefined pattern '$p'";
            }
            $wanted{$p} = undef;
        }

        # If message_pattern is set to '%T %L %m' then the code
        # should looks like:
        #
        #   sub {
        #       my ($w, $m) = @_; # %wanted pattern, %message
        #       $m->{$_} = $w->{$_} for qw/time level message/;
        #   }

        my $func = 'sub { my ($w, $m) = @_; $m->{$_} = $w->{$_} for qw/';
        $func .= join(' ', map { $pattern->{$_}->{name} } keys %wanted);
        $func .= '/ }';
        $options{message_pattern_func} = $func;
        $options{message_pattern_code} = eval $func;
        Carp::croak $@ if $@;
    }

    if ($options{message_layout}) {
        my (@chunks, $func);

        # If the message layout is set to '%T [%L] %m' then the code
        # should looks like:
        #
        #   sub {
        #       my ($w, $m) = @_; # %wanted pattern, %message
        #       $m->{'message'} = 
        #           $w->{'time'}
        #           . ' ['
        #           . $w->{'level'}
        #           . '] '
        #           . $w->{'message'}
        #       );
        #   }

        foreach my $p ( split /(?:(%[a-zA-Z])|(%)%)/, $options{message_layout} ) {
            next unless defined $p && length($p);
            if ( exists $pattern->{$p} ) {
                $wanted{$p} = undef;
                my $name = $pattern->{$p}->{name};
                push @chunks, "\$w->{'$name'}";
            } else {
                # quote backslash and apostrophe
                $p =~ s/\\/\\\\/g;
                $p =~ s/'/\\'/g;
                push @chunks, "'$p'";
            }
        }

        if (@chunks) {
            $func  = 'sub { my ($w, $m) = @_; $m->{message} = ';
            $func .= join('.', @chunks);
            $func .= ' }';
        }

        $options{message_layout_func} = $func;
        $options{message_layout_code} = eval $func;
        Carp::croak $@ if $@;
    }

    # %m is default
    delete $wanted{'%m'};

    # The references to the patterns are stored to all outputs.
    # If a pattern will be changed with set_pattern() then the
    # changed pattern is available for each output.
    $options{wanted_pattern} = [ map { $pattern->{$_} } keys %wanted ];
    return \%options;
}

sub _validate_filter {
    my ($self, $args) = @_;
    my $ref = ref($args);
    my %filter;

    # A filter can be passed as CODE, as a Regexp, as a simple string
    # that will be embed in a Regexp or as a condition.

    if ($ref eq 'CODE') {
        $filter{code} = $args;
    } elsif ($ref eq 'Regexp') {
        $filter{code} = sub { $_[0]->{message} =~ $args };
    } elsif (!$ref) {
        $filter{code} = sub { $_[0]->{message} =~ /$args/ };
    } else {
        %filter = %$args;

        # Structure:
        #   $filter->{code}             = &code
        #   $filter->{func}             = $code_as_string
        #   $filter->{condition}        = $users_condition
        #   $filter->{result}->{matchN} = $result_of_matchN
        #   $filter->{matchN}           = qr//
        #
        # Each matchN will be checked on the message and the BOOL results
        # will be stored to $filter->{result}->{matchN}. Then the results
        # will be passed to &code. &code returns 0 or 1.
        #
        # As example if the filter is set to
        #
        #   filter => {
        #       match1    => qr/foo/,
        #       match2    => qr/bar/,
        #       condition => '(match1 && match2)',
        #   }
        #
        # Then the bool results will be saved:
        #
        #   $filter->{result}->{match1} = $message =~ $filter->{match1};
        #   $filter->{result}->{match2} = $message =~ $filter->{match2};
        #
        # The code for the filter should looks like:
        #
        #   $filter->{code} =
        #       sub {
        #           my $m = shift;
        #           ($m->{match1} && $m->{match2})
        #       }
        #
        #   &$code($filter->{result});

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

        $filter{func}  =  'sub { my $m = shift; ';
        $filter{func} .=  $filter{condition}.'; }';
        $filter{func}  =~ s/(match\d+)/\$m->{$1}/g;
        $filter{code}  =  eval $filter{func};
    }

    return \%filter;
}

sub _raise_error {
    $ERRSTR = $_[1];
    return undef;
}

1;
