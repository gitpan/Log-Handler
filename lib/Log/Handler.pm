=head1 NAME

Log::Handler - A simple handler to log messages to log files.

=head1 SYNOPSIS

    use Log::Handler;

    my $log = Log::Handler->new();

    $log->add(filename => \*STDOUT);

    $log->alert("foo bar");

=head1 DESCRIPTION

This module is just a simple object oriented log file handler and very easy to use.
It's possible to define a log level for your programs and control the amount of
informations that will be logged to log files. In addition it's possible to configure
how you wish to open the log files - transient or permanent - and lock and unlock the
log files by each write operation. If you wish you can assign the handler to check the
inode of the log files (not on Windows). That could be very useful if a rotate
mechanism moves and zip the log file.

=head1 WHAT IS NEW, WHAT IS DEPRECATED

=head2 More than one log file

Since version 0.39 the method C<add()> is totaly new. With this method it's now possible to
add further log files to the handler and define a own level range each log file. As example
you can log the levels 0-4 (emerg-warn) to log file A and the levels 4-7 (warn-debug)
to log file B.

=head2 Log::Handler::Logger

The main logic of Log::Handler is moved to Log::Handler::Logger. If you add a new log file
to the handler the file got it's own Log::Handler::Logger object and the Log::Handler just
dispatch messages to the file objects.

=head2 Placeholder

Placeholders are now available for the prefix in printf style. The old style of <--LEVEL-->
is deprecated, instead you have to use %L as example. In addition a postfix option is
available now. Take a look to the documentation of prefix and postfix.

=head2 Kicked methods

The methods C<close()>, C<get_prefix()> and C<set_prefix()> are not available any more.

=head2 trace()

The method C<trace()> writes C<caller()> informations to all log files by default.
It's possible to disable this by set trace to 0.

=head2 Examples

Take a look to the example directory of the distribution if you need a code example.

=head1 METHODS

=head2 new()

Call C<new()> to create a new log handler object.

You can pass the options for the first log file if you want or later by the call of C<add()>.

=head2 add()

Call C<add()> to add a log file to the object. C<add()> expects the options for the log file.
Each option will be set to a default value if not set.

=head2 Log levels

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

Both calls write to the log file (provided that the log level INFO would log)

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
would write the message to the log file. All methods returns TRUE if the handler would
log it and FALSE if not. Example:

    $log->debug(Dumper(\%hash));

This example would dump the hash in any case and handoff it to the log handler, 
but this isn't that what we really want because it could costs a lot of resources.

    $log->debug(Dumper(\%hash))
       if $log->is_debug();

Now we dump the hash only if the current log level would log it.

The methods C<is_note()>, C<is_warn()>, C<is_err()>, C<is_crit()> and C<is_emerg()>
are just shortcuts.

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

Call C<errstr()> if you want to get the last error message. That is useful with
C<die_on_errors>. If you set this option to C<0> then the handler wouldn't croak
if a simple write operation fails. Set C<die_on_errors> to control it yourself.

    $log->info("Hello World!") or die $log->errstr;

Or

    unless ( $log->info("Hello World!") ) {
        $error_string = $log->errstr;
    }

The exception is that the handler croaks in any case if the call of C<new()> or C<add()>
fails because on missing params or wrong settings!

    my $log = Log::Handler->new(filename => 'file.log', mode => 'foo bar');

That would croak, because the option C<mode> except C<append> or C<trunc> or C<excl>.

If you set the option C<fileopen> to 1 - the default - to open the log file permanent
and the call of C<new> fails then you can absorb the error.

    my $log = Log::Handler->new(
        filename        => 'file.log',
        die_on_errors   => 0
    ) or warn Log::Handler->errstr;

=head2 config()

With this method it's possible to load your logger configuration from a file.

    $log->config(filename => 'file.conf');

Take a look into the documentation of L<Log::Handler::Config> for more informations.

=head1 OPTIONS

=head2 filename

With C<filename> you can set a file name, a GLOBREF or you can set a string as an alias
for STDOUT or STDERR. The default is STDOUT for this option.

Set a file name:

    my $log = Log::Handler->new( filename => 'file.log'  );

Set a GLOBREF

    open FH, '>', 'file.log' or die $!;
    my $log = Log::Handler->new( filename => \*FH );

Or the same with

    open my $fh, '>', 'file.log' or die $!;
    my $log = Log::Handler->new( filename => $fh );

Set STDOUT or STDERR

    my $log = Log::Handler->new( filename => \*STDOUT );
    # or
    my $log = Log::Handler->new( filename => \*STDERR );

If the option C<filename> is set in a config file and you want to debug to your screen then
you can set C<*STDOUT> or C<*STDERR> as a string.

    my $log = Log::Handler->new( filename => '*STDOUT' );
    # or
    my $log = Log::Handler->new( filename => '*STDERR' );

That is not possible:

    my $log = Log::Handler->new( filename => '*FH' );

Note that if you set a GLOBREF to C<filename> some options will be forced (overwritten)
and you have to control the handles yourself. The forced options are

    fileopen => 1
    filelock => 0
    reopen   => 0

=head2 filelock

Maybe it's desirable to lock the log file by each write operation because a lot of processes
write at the same time to the log file. You can set the option C<filelock> to 0 or 1.

    0 - no file lock
    1 - exclusive lock (LOCK_EX) and unlock (LOCK_UN) by each write operation (default)

=head2 fileopen

Open a log file transient or permanent.

    0 - open and close the logfile by each write operation
    1 - open the logfile if C<new()> called and try to reopen the
        file if C<reopen> is set to 1 and the inode of the file has changed (default)

=head2 reopen

This option works only if option C<fileopen> is set to 1.

    0 - deactivated
    1 - try to reopen the log file if the inode changed (default)

=head2 fileopen and reopen

Please note that it's better to set C<reopen> and C<fileopen> to 0 on Windows
because Windows unfortunately haven't the faintest idea of inodes.

To write your code independent you should control it:

    my $os_is_win = $^O =~ /win/i ? 0 : 1;

    my $log = Log::Handler->new(
       filename => 'file.log',
       mode     => 'append',
       fileopen => $os_is_win
    );

If you set C<fileopen> to 0 then it implies that C<reopen> has no importance.

=head2 mode

There are three possible modes to open a log file.

    append - O_WRONLY | O_APPEND | O_CREAT
    excl   - O_WRONLY | O_EXCL   | O_CREAT (default)
    trunc  - O_WRONLY | O_TRUNC  | O_CREAT

C<append> would open the log file in any case and appends the messages at
the end of the log file.

C<excl> would fail by open the log file if the log file already exists.
This is the default option because some security reasons.

C<trunc> would truncate the complete log file if it exists. Please take care
to use this option.

Take a look to the documentation of C<sysopen()> to get more informations.

=head2 autoflush

    0 - autoflush off
    1 - autoflush on (default)

=head2 permissions

The option C<permissions> sets the permission of the file if it creates and must
be set as a octal value. The permission need to be in octal and are modified
by your process's current "umask".

That means that you have to use the unix style permissions such as C<chmod>.
C<0640> is the default permission for this option. That means that the owner got
read and write permissions and users in the same group got only read permissions.
All other users got no access.

Take a look to the documentation of C<sysopen()> to get more informations.

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

=head2 PLACEHOLDER prefix, postfix

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
    %C  Filename and line number where the logger was called
    %S  The program name

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
alert, critical (crit) and error (err) are active and would be logged to the log file.

You can set both to 8 or C<nothing> if you don't want to log any message.

=head2 rewrite_to_stderr

Set this option to 1 if you want that Log::Handler prints messages to STDERR if the message
couldn't print to the log file. The default is 0.

=head2 die_on_errors

Set C<die_on_errors> to 0 if you don't want that the handler croaks if normal operations fail.

    0 - will not die on errors
    1 - will die (e.g. croak) on errors

The exception is that the handler croaks in any case if the call of C<new()> fails because
on missing params or wrong settings.

=head2 utf8

If this option is set to 1 then UTF-8 will be set with C<binmode()> on the output filehandle.

=head2 trace

With this options it's possible to disable the tracing for a log file. By default this
option is set to 1 and tracing is enabled.

=head2 debug

You can activate a simple debugger that writes C<caller()> informations for each log level
that would log to the log file. The debugger is logging all defined values except C<hints>
and C<bitmask>. Set C<debug> to 1 to activate the debugger. The debugger is set to 0 by default.

=head2 debug_mode

There are two debug modes: line(1) and block(2) mode. The default mode is 1.

The block mode looks like this:

    use strict;
    use warnings;
    use Log::Handler;

    my $log = Log::Handler->new(
       maxlevel   => 'debug',
       debug      => 1,
       debug_mode => 1
    );

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

    my $log = Log::Handler->new(
       filename => 'file1.log',
       mode     => 'append',
       newline  => 1,
       maxlevel => 7,
       minlevel => 0
    );

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

    $log->add(
       filename => 'debug.log',
       mode     => 'append',
       maxlevel => 7,
       minlevel => 7
    );

    $log->add(
       filename => 'common.log',
       mode     => 'append',
       maxlevel => 6,
       minlevel => 5
    );

    $log->add(
       filename => 'error.log',
       mode     => 'append',
       maxlevel => 4,
       minlevel => 0
    );

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

    # force caller() informations to all log files
    $log->trace("this message goes to all log files");

=head2 Just a notice:

    use Log::Handler;

    my $log = Log::Handler->new(
       filename   => '/var/run/pid-file1',
       mode       => 'trunc',
       maxlevel   => 5,
       minlevel   => 5,
       prefix     => '',
       timeformat => ''
    );

    $log->note($$);

Would truncate /var/run/pid-file1 and write just the pid to the logfile.

=head2 Selfmade prefix:

    use Log::Handler;
    use Sys::Hostname;

    my $hostname =  hostname;
    my $pid      =  $$;
    my $progname =  $0;
       $progname =~ s@.*[/\\]@@;

    my $log = Log::Handler->new(
       filename => "${progname}.log",
       mode     => 'append',
       maxlevel => 6,
       newline  => 1,
       prefix   => "%H[%P] [%L] %S: "
    );

    $log->info("Hello World!");
    $log->warning("There is something wrong!");

Would log:

    Feb 01 12:56:31 hostname[8923] [INFO] progname: Hello world
    Feb 01 12:56:31 hostname[8923] [WARNING] progname: There is something wrong!

=head2 is_* example:

    use Log::Handler;
    use Data::Dumper;

    my $log = Log::Handler->new(
       filename   => 'file1.log',
       mode       => 'append',
       maxlevel   => 4,
    );

    my %hash = (foo => 1, bar => 2);

    $log->debug("\n".Dumper(\%hash))
        if $log->is_debug();

Would NOT dump %hash to the $log object!

=head2 die_on_errors example:

    use Log::Handler;
    use Data::Dumper;

    my $log = Log::Handler->new(
       filename      => 'file1.log',
       mode          => 'append',
       die_on_errors => 0
    ) or die Log::Handler->errstr();

    if ($log->is_debug()) {
       $log->debug("\n".Dumper(\%hash))
          or die $log->errstr();
    }

=head1 PREREQUISITES

    Fcntl             -  for flock(), O_APPEND, O_WRONLY, O_EXCL and O_CREATE
    POSIX             -  to generate the time stamp with strftime()
    Params::Validate  -  to validate all options
    Devel::Backtrace  -  to backtrace caller()
    Carp              -  to croak() on errors if die_on_errors is active
    Sys::Hostname     -  to get the current hostname
    Config::General   -  to load configuration from a file

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
our $VERSION = '0.38_03';

use strict;
use warnings;
use Log::Handler::Logger;
use Log::Handler::Config;
$Log::Handler::Logger::CALLER = 4;
$Log::Handler::ERRSTR = '';

# --------------------------------------------------------------------
# The BEGIN block is used to generate the syslog methods and the is_*
# methods. The syslog methods calling write() with the syslog level
# as first uppercase argument if the current log level is valid.
# The is_* methods are only used to check if the current set of max-
# and minlevel would log the message to the log file and returns TRUE
# or FALSE. The levels NOTE, ERR, CRIT and EMERG are just shortcuts.
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

            next if $routine eq 'trace';

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
    my $self  = bless { }, $class;
    if (@_) {
        $self->add(@_);
    }
    return $self;
}

sub add {
    my $self = shift;
    my $logger = Log::Handler::Logger->new(@_);

    # There are 2 ways to add the logger objects. The one way is to
    # push all objects into a array or build a hash and if one of the
    # log level methods is called the array or hash must be iterated
    # to find out which logger would log. Example:
    #
    #       push @{$self->{logger}}, $logger;
    #
    #       sub info {
    #           my $self = shift;
    #           foreach my $logger ( @{$self->{logger}} ) {
    #               if ($logger->would_log('INFO')) {
    #                   $logger->write('INFO', @_) or return undef;
    #               }
    #           }
    #           return 1;
    #       }
    #
    # I though that's a bad way because if 4 log files are added then
    # all logger objects would be checked by each call. For this reason
    # I though it's better to build a HoA with all active levels as hashkeys
    # and push the logger objects into the active levels. So it's doesn't
    # necessary to iterate over all logger objects and it must be only
    # checked if a level is defined and iterate over logger objects that
    # are pushed into this array. Example:
    #
    #       push @{$self->{levels}->{INFO}}, $logger;
    #
    #       sub info {
    #           my $self  = shift;
    #           if ( $self->{levels}->{'INFO'} ) {
    #               foreach my $logger ( @{$self->{levels}->{'INFO'}} ) {
    #                   $logger->write('INFO', @_) or return undef;
    #               }
    #           }
    #           return 1;
    #       }
    #
    # That's much faster as the first example.

    # Iterate all level and if a level is active the logger is pushed into the array
    foreach my $level (qw/DEBUG INFO NOTICE WARNING ERROR CRITICAL ALERT EMERGENCY TRACE/) {
        if ( $logger->would_log($level) ) {
            push @{$self->{levels}->{$level}}, $logger;
        }
    }

    return $self;
}

sub config {
    my $self = shift;
    my $configs = Log::Handler::Config->config(@_);
    $self->add($_) for @$configs;
}

sub errstr { $Log::Handler::ERRSTR }

1;
