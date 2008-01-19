=head1 NAME

Log::Handler - Log messages to different outputs.

=head1 SYNOPSIS

    use Log::Handler;

    my $log = Log::Handler->new();

    $log->add(File => {
        filename => 'file.log',
        maxlevel => 'debug',
        minlevel => 'warn',
        newline  => 1,
    });

    $log->alert("foo bar");

=head1 DESCRIPTION

This module is just a simple object oriented log handler and very easy to use.
It's possible to define a log level for your programs and control the amount of
informations that will be logged to one or more outputs. The outputs are different
modules in the Log::Handler::Logger subtree and it's possible to extend it.

=head1 WHAT IS NEW, WHAT IS DEPRECATED

=head2 Backward compatibilities

As I re-designed the Log::Handler it was my wish to support the old style in version 0.38.
The one exception is that the option C<redirect_to_stderr> doesn't exist any more. In all
other cases you can use all things from 0.38.

=head2 More than one output

Since version 0.38_01 the method C<add()> is totaly new. With this method it's now possible
to add output objects as much as you wish, each with an own level range and different other
options. As example you can log the levels 0-4 (emerg-warn) to one object and the levels
4-7 (warn-debug) to another object. In addition you want to forward all log levels to a
subroutine. That's possible.

=head2 Log::Handler::Logger

The main logic of Log::Handler is moved to Log::Handler::Logger. The Log::Handler just
manage all logger objects and forward messages to it if the current log handler would
log.

=head2 Placeholder

Placeholders are now available for the prefix in printf style. The old style of <--LEVEL-->
is deprecated, instead you have to use %L as example. In addition a postfix option is
available now. Take a look to the documentation of prefix and postfix.

=head2 Configuration file

Now it's possible to load the configuration from a file or define defaults. For this purpose
I wrote C<Log::Handler::Config>.

=head2 Kicked methods

The methods C<close()>, C<get_prefix()> and C<set_prefix()> are not available any more.

=head2 Kicked options

C<rewrite_to_stderr>.

=head2 trace()

The method C<trace()> writes C<caller()> informations to all logger by default.
It's possible to disable this by set trace to 0.

=head2 Further releases

Extensions and further changes are planed. I hope I have enough time to implement my
ideas as soon as possible!

=head1 METHODS

=head2 new()

Call C<new()> to create a new log handler object.

    my $log = Log::Handler->new();

=head2 add()

Call C<add()> to add a new logger.

There are different ways to add a new logger object to the handler. In the following
example I show you one simple way:

    use Log::Handler;
    use Log::Handler::Logger::File;

    # the logger options (how to handle the file)
    my %logger_options = (
        timeformat      => '%Y/%m/%d %H:%M:%S',
        newline         => 1,
        prefix          => '%T [%L] %S: ',
        postfix         => '',
        maxlevel        => 'debug',
        minlevel        => 'emergency',
        die_on_errors   => 1,
        trace           => 1,
        debug           => 0,
        debug_mode      => 2,
        debug_skip      => 0,
    );

    # the options for the file
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

    # we creating the objects
    my $log  = Log::Handler->new();
    my $file = Log::Handler::Logger::File->new( \%file_options );

    # now we add the file object to the handler and the logger options
    $log->add( $file => \%logger_options );

But it can be simplier! You can pass all options for the logger and for the
file in one step. You just need to tell the handler what do you want to add.

    use Log::Handler;

    my %all_options = (%logger_options, %file_options);

    $log->add( file => \%all_options );

Further examples:

    $log->add( email => \%all_options );
    $log->add( forward => \%all_options );

=head2 Log level methods

There are eigth log level methods (thirteen with shortcuts):

=over 4

=item debug()

=item info()

=item notice(), note()

=item warning(), warn()

=item error(), err()

=item critical(), crit()

=item alert()

=item emergency(), emerg()

=back

C<debug()> is the highest and C<emergency()> or C<emerg()> is the lowest log level.
You can define the log level with the options C<maxlevel> and C<minlevel>.

The methods C<note()>, C<warn()>, C<err()>, C<crit()> and C<emerg()> are just shortcuts.

Example:

If you set the option C<maxlevel> to C<warning> and C<minlevel> to C<emergency>
then the levels emergency, alert, critical, error and warning will be logged.

The call of a log level method is very simple:

    $log->info("Hello World! How are you?");

Or maybe:

    $log->info("Hello World!", "How are you?");

Both calls would log

    Feb 01 12:56:31 [INFO] Hello World! How are you?

=head2 is_* methods

=over 4

=item is_debug()

=item is_info()

=item is_notice(), is_note()

=item is_warning(), is_warn()

=item is_error(), is_err()

=item is_critical(), is_crit()

=item is_alert()

=item is_emergency(), is_emerg()

=back

These thirteen methods could be very useful if you want to kwow if the current log level
would output the message. All methods returns TRUE if the current set of minlevel and
maxlevel would log the message and FALSE if not. Example:

    $log->debug(Dumper(\%hash));

This example would dump the hash in any case and pass it to the log handler, 
but that is not that what we really want!

    if ( $log->is_debug ) {
        $log->debug(Dumper(\%hash));
    }

Now we dump the hash only if the current log level would log it.

The methods C<is_note()>, C<is_warn()>, C<is_err()>, C<is_crit()> and C<is_emerg()>
are just shortcuts.

=head2 fatal(), is_fatal()

This are special methods that can be used for CRITICAL, ALERT and EMERGENCY messages.
A lot of people like to use just the levels DEBUG, INFO, WARN, ERROR and FATAL so I 
though to implement this. You just have to set C<minlevel> to C<critical>, C<alert>
or C<emergency> to use it.

=head2 trace()

This method is a special log level and very useful if you want to print C<caller()>
informations to all log files.

In contrast to the log level methods this method prints C<caller()> informations
to all log files in any case and you don't need to activate the debugger with the
option C<debug>. Example:

    my $log = Log::Handler->new( filename => \*STDOUT );
    $log->trace("caller informations:");

    Jun 05 21:20:32 [TRACE] caller informations
       CALL(2): package(main) filename(./log-handler-test.pl) line(22) subroutine(Log::Handler::trace) hasargs(1)
       CALL(1): package(Log::Handler) filename(/usr/local/share/perl/5.8.8/Log/Handler.pm) line(941) subroutine(Log::Handler::_write) hasargs(1)
       CALL(0): package(Log::Handler) filename(/usr/local/share/perl/5.8.8/Log/Handler.pm) line(1097) subroutine(Devel::Backtrace::new) hasargs(1) wantarray(0)

Maybe you like to print C<caller()> informations to all log files if an unexpected error occurs.

    $SIG{__DIE__} = sub { $log->trace(@_) };

Take a look at the examples of the options C<debug>, C<debug_mode> and C<debug_skip>
for more informations.

=head2 errstr()

Call C<errstr()> if you want to get the last error message. This is useful with
C<die_on_errors>. If you set C<die_on_errors> to C<0> then the handler wouldn't
croak if a simple write operation fails. Set C<die_on_errors> to control it yourself.

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
    }

The exception is that the handler croaks in any case if the call of C<new()> or C<add()>
fails because on missing or wrong settings!

=head2 config()

With this method it's possible to load your logger configuration from a file.

    $log->config(filename => 'file.conf');

Take a look into the documentation of L<Log::Handler::Config> for more informations.

=head1 LOGGER OPTIONS

=head2 timeformat

You can set C<timeformat> with a date and time format that will be coverted
by POSIX::strftime. The default format is "%b %d %H:%M:%S" and looks like

    Feb 01 12:56:31

As example the format "%Y/%m/%d %H:%M:%S" would looks like

    2007/02/01 12:56:31

=head2 newline

This helpful option appends a newline to the log message if it not exist.

    0 - inactive (default)
    1 - active - appends a newline to the log message if not exist

=head2 prefix, postfix

It's possible to define a C<prefix> and C<postfix> for each message that will
be logged to the log file. The C<prefix> will be written before and the C<postfix>
after the message. Within the C<prefix> and C<postfix> it's possible to use
different placeholders that will be replaced before the message goes to the log
file.

The available placeholders are:

    %L  Log level
    %T  Timestamp
    %P  PID
    %H  Hostname
    %N  Newline
    %C  Caller - filename and line number where the logger was called
    %S  Script - the program name
    %M  Measurement - replaced with the time since the last call of the handler
    %m  The same as %M just 3 internal decimal places (0.001)

The default C<prefix> is set to "%T [%L] ". The C<postfix> is not defined by default.
As example the following code

    $log->alert("foo bar");

would log by default

    Feb 01 12:56:31 [ALERT] foo bar

If you set C<prefix> and C<postfix> to

    prefix  => '%T foo %L bar '
    postfix => ' (%C)'

and call

    $log->info("baz");

then it would log

    Feb 01 12:56:31 foo INFO bar baz (script.pl, line 40)

Traces will be added after the C<postfix>.

=head2 maxlevel and minlevel

With these options it's possible to set the log levels for your program.
The log levels are:

    7 - debug
    6 - info
    5 - notice, note
    4 - warning, warn
    3 - error, err
    2 - critical, crit
    1 - alert
    0 - emergency, emerg

The levels C<note>, C<err>, C<crit> and C<emerg> are just shortcuts.

It's possible to set the log level as a string or as number. The default
C<maxlevel> is 4 and the default C<minlevel> is 0.

Example: If C<maxlevel> is set to 4 and C<minlevel> to 0 then the levels emergency (emerg),
alert, critical (crit) and error (err) are active and would be logged.

You can set both to 8 or C<nothing> if you don't want to log any message.

=head2 die_on_errors

Set C<die_on_errors> to 0 if you don't want that the handler croaks if normal operations fail.

    0 - will not die on errors
    1 - will die (e.g. croak) on errors

The exception is that the handler croaks in any case if the call of C<new()> fails because
on missing params or wrong settings.

=head2 trace

With this options it's possible to disable the tracing for a logger. By default this
option is set to 1 and tracing is enabled.

=head2 debug

You can activate a simple debugger that writes C<caller()> informations for each log level
that would logged. The debugger is logging all defined values except C<hints> and C<bitmask>.
Set C<debug> to 1 to activate the debugger. The debugger is set to 0 by default.

=head2 debug_mode

There are two debug modes: line(1) and block(2) mode. The default mode is 1.

The block mode looks like this:

    use strict;
    use warnings;
    use Log::Handler;

    my $log = Log::Handler->new()

    $log->add(file => {
        filename   => '*STDOUT',
        maxlevel   => 'debug',
        debug      => 1,
        debug_mode => 1
    });

    sub test1 { $log->debug() }
    sub test2 { &test1; }

    &test2;

Output:

    Apr 26 12:54:11 [DEBUG] 
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

=head2 debug_skip

This option let skip the C<caller()> informations the count of C<debug_skip>.

    debug_skip => 2

    Apr 26 12:55:07 [DEBUG] 
       CALL(2): package(main) filename(./trace.pl) line(16) subroutine(main::test2) hasargs(0)
       CALL(1): package(main) filename(./trace.pl) line(14) subroutine(main::test1) hasargs(0)
       CALL(0): package(main) filename(./trace.pl) line(13) subroutine(Log::Handler::__ANON__) hasargs(1)

=head1 EXAMPLES

=head2 Simple example to log all level to one log file:

    use Log::Handler;

    my $log = Log::Handler->new();

    $log->add(file => {
       filename => 'file1.log',
       mode     => 'append',
       newline  => 1,
       maxlevel => 7,
       minlevel => 0
    });

    $log->debug("this is a debug message");
    $log->info("this is a info message");
    $log->notice("this is a notice");
    $log->note("this is a notice as well");
    $log->warning("this is a warning");
    $log->warn("this is a warning as well");
    $log->error("this is a error message");
    $log->err("this is a error message as well");
    $log->critical("this is a critical message");
    $log->crit("this is a critical message as well");
    $log->alert("this is a alert message");
    $log->emergency("this is a emergency message");
    $log->emerg("this is a emergency message as well");

Would log

    Feb 01 12:56:31 [DEBUG] this is a debug message
    Feb 01 12:56:31 [INFO] this is a info message
    Feb 01 12:56:31 [NOTICE] this is a notice
    Feb 01 12:56:31 [NOTICE] this is a notice as well
    Feb 01 12:56:31 [WARNING] this is a warning
    Feb 01 12:56:31 [WARNING] this is a warning
    Feb 01 12:56:31 [ERROR] this is a error message
    Feb 01 12:56:31 [ERROR] this is a error message as well
    Feb 01 12:56:31 [CRITICAL] this is a critical message
    Feb 01 12:56:31 [CRITICAL] this is a critial message as well
    Feb 01 12:56:31 [ALERT] this is a alert message
    Feb 01 12:56:31 [EMERGENCY] this is a emergency message
    Feb 01 12:56:31 [EMERGENCY] this is a emergency message as well

=head2 Different log files:

    use Log::Handler;

    # create the log handler object
    my $log = Log::Handler->new;

    $log->add(file => {
        filename => 'debug.log',
        mode     => 'append',
        maxlevel => 7,
        minlevel => 7,
        trace    => 1,
    });

    $log->add(file => {
        filename => 'common.log',
        mode     => 'append',
        maxlevel => 6,
        minlevel => 5,
        trace    => 0,
    });

    $log->add(file => {
        filename => 'error.log',
        mode     => 'append',
        maxlevel => 4,
        minlevel => 0,
        trace    => 1,
    });

    # log to debug.log
    $log->debug("this is a debug message");

    # log to common.log
    $log->info("this is a info message");
    $log->notice("this is a notice");
    $log->note("this is a notice as well");

    # log to error.log
    $log->warning("this is a warning");
    $log->warn("this is a warning as well");
    $log->error("this is a error message");
    $log->err("this is a error message as well");
    $log->critical("this is a critical message");
    $log->crit("this is a critical message as well");
    $log->alert("this is a alert message");
    $log->emergency("this is a emergency message");
    $log->emerg("this is a emergency message as well");

    # force caller() informations just to error.log and debug.log
    $log->trace("this message goes to all log files");

=head2 Just a notice:

    use Log::Handler;

    my $log = Log::Handler->new();

    $log->add(file => {
       filename   => '/var/run/pid-file1',
       mode       => 'trunc',
       maxlevel   => 5,
       minlevel   => 5,
       prefix     => '',
       timeformat => ''
    });

    $log->note($$);

Would truncate /var/run/pid-file1 and write just the pid to the logfile.

=head2 Selfmade prefix:

    use Log::Handler;

    my $log = Log::Handler->new();

    $log->add(file => {
       filename => "${progname}.log",
       mode     => 'append',
       maxlevel => 6,
       newline  => 1,
       prefix   => "%H[%P] [%L] %S: "
    });

    $log->info("Hello World!");
    $log->warning("There is something wrong!");

Would log:

    Feb 01 12:56:31 hostname[8923] [INFO] progname: Hello world
    Feb 01 12:56:31 hostname[8923] [WARNING] progname: There is something wrong!

=head2 is_* example:

    use Log::Handler;
    use Data::Dumper;

    my $log = Log::Handler->new();

    $log->add(file => {
       filename   => 'file1.log',
       mode       => 'append',
       maxlevel   => 4,
    });

    my %hash = (foo => 1, bar => 2);

    $log->debug("\n".Dumper(\%hash))
        if $log->is_debug();

Would NOT dump %hash to the $log object!

=head1 EXTENSIONS

Do you want write further extensions? There are just some requirements!

Logger objects should provide a C<new()> and a C<write()> method.

Config plugins should provide a C<get_config()> routine.

Take a look into the source or write me a mail if you have questions.

=head1 PREREQUISITES

Prerequisites for all modules:

    Carp
    Config::General
    Devel::Backtrace
    Fcntl
    Net::SMTP
    Params::Validate
    POSIX
    Time::HiRes
    Sys::Hostname
    UNIVERSAL::require

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

    * Log::Handler::Logger::DBI
    * Log::Handler::Logger::Socket

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
our $VERSION = '0.38_05';
our $ERRSTR  = '';
$Log::Handler::Logger::CALLER = 4;

use Carp;
use Log::Handler::Config;
use Log::Handler::Logger;
use Log::Handler::Logger::File;

# --------------------------------------------------------------------
# The BEGIN block is used to generate the syslog methods and the is_*
# methods. The syslog methods calling write() with the syslog level
# as first uppercase argument if the current log level is valid.
# The is_* methods are only used to check if the current set of max-
# and minlevel would log the message and returns TRUE or FALSE. The
# levels NOTE, ERR, CRIT and EMERG are just shortcuts. Other levels
# are special like FATAL, TRACE, etc.
# --------------------------------------------------------------------

BEGIN {
    my %LEVELS_BY_ROUTINE = (
        debug     => 'DEBUG',
        info      => 'INFO',
        notice    => 'NOTICE',
        note      => 'NOTICE',
        warning   => 'WARNING',
        warn      => 'WARNING',
        error     => 'ERROR',
        err       => 'ERROR',
        critical  => 'CRITICAL',
        crit      => 'CRITICAL',
        alert     => 'ALERT',
        emergency => 'EMERGENCY',
        emerg     => 'EMERGENCY',
        trace     => 'TRACE',
        fatal     => 'FATAL',

# thinking about ......
#        carp      => 'FATAL',
#        croak     => 'FATAL',
#        cluck     => 'FATAL',
#        confess   => 'FATAL',
#        die       => 'FATAL',
#        exit      => 'NOTICE', # exit is normal, not fatal!

    );

    while ( my ($routine, $level) = each %LEVELS_BY_ROUTINE ) {

        {   # start "no strict 'refs'" block
            no strict 'refs';

            # --------------------------------------------------------------
            # Creating the 8 syslog level methods - total 13 with shortcuts:
            # debug(), info(), notice(), note(), warning(), warn(), error(),
            # err(), critical(), crit(), alert(), emergency(), emerg()
            # --------------------------------------------------------------

            *{"$routine"} = sub {
                my $self  = shift;

                if ( $self->{levels}->{$level} ) {
                    foreach my $logger ( @{$self->{levels}->{$level}} ) {
                        $logger->write($level, @_) or return undef;
                    }
                }

                return 1;
            };

            next if $level eq 'TRACE';

            # -------------------------------------------------------------
            # Creating the 8 is_ level methods - total 13 with shortcuts:
            # is_debug(), is_info(), is_notice(), is_note(),  is_warning(),
            # is_warn(), is_error(), is_err(), is_critical(), is_crit()
            # is_alert(), is_emergency(), is_emerg()
            # -------------------------------------------------------------

            *{"is_$routine"} = sub {
                my $self = shift;
                return $self->{levels}->{$level} ? 1 : 0;
            };

        } # end "no strict 'refs'" block
    }
}

sub new {
    my $class = shift;
    my $self  = bless { levels => { } }, $class;
    if (@_) {
        $self->add(File => @_);
    }
    return $self;
}

sub add {
    @_ > 2 or Carp::croak 'Usage: $log->add($type => \%options)';
    my $self   = shift;
    my $logger = Log::Handler::Logger->new(@_);
    my $levels = $self->{levels};

    # Iterate all level and push the active levels into a HoA.
    # This way makes it possible to check very fast if a log
    # level is active and iterate over all objects.

    foreach my $level (qw/DEBUG INFO NOTICE WARNING ERROR CRITICAL ALERT EMERGENCY FATAL TRACE/) {
        if ( $logger->would_log($level) ) {
            push @{$levels->{$level}}, $logger;
        }
    }

    return $self;
}

sub config {
    my $self = shift;
    my $configs = Log::Handler::Config->config(@_);

    while ( my ($type, $config) = each %$configs ) {
        $self->add($type, $_) for @$config;
    }
}

sub errstr { $ERRSTR }

1;
