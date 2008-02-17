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
It's possible to define a log level for your programs and control the amount of
informations that are logged to one or more outputs.

=head1 WHAT IS NEW, WHAT IS DEPRECATED

=head2 More than one output

Since version 0.40 the method C<add()> is totaly new. With this method you can add outputs
as much as you wish, each with its own level range and different other options. As example
you can add a output for the levels 0-4 (emergency-warning) and another output for the
levels 4-7 (warning-debug). Each output is handled as a own object.

=head2 Log::Handler::Output

This module is used to build the output message and is just for internal usage.

=head2 Outputs

There are different output modules available:

    Log::Handler::Output::File
    Log::Handler::Output::DBI
    Log::Handler::Output::Email
    Log::Handler::Output::Forward
    Log::Handler::Output::Screen

You can add the outputs on different ways. Take a look to the further documentation.

=head2 Message layout

Placeholders are now available for the message layout in C<printf()> style. The old style of
<--LEVEL--> is deprecated and you should use C<%L> instead. The layout can be defined
with the option C<message_layout>. C<prefix> is deprecated as well.

=head2 Configuration file

Now it's possible to load the configuration from a file. There are 3 configuration
plugins available:

    Config::General
    Config::Properties
    YAML

Take a look into the documentation for L<Log::Handler::Config>.

=head2 New options

    dateformat
    priority
    message_pattern

=head2 Changed options

    prefix  is now  message_layout
    debug   is now  debug_trace

=head2 Kicked options

    rewrite_to_stderr

=head2 New methods

    add()           - to add new outputs
    config()        - to load outputs from a configuration file
    set_pattern()   - to create your own placeholder

=head2 New level methods

Please take a look to L<Log::Handler::Levels> because the list is very long.

=head2 Kicked methods

    note()
    close()
    get_prefix()
    set_prefix()

=head2 Changed methods

    trace()  replaced with trace methods for each level
    warn()   still exist but is a replacement vor carp() now

=head2 Backward compatibilities

As I re-designed the Log::Handler it was my wish to support the most things from version 0.38.

    my $log = Log::Handler->new(filename => 'file.log');

That still running fine because the options are passed as a file output. The exceptions
that you should take a look the the kicked/changed methods and options.

=head2 Further releases

Extensions and changes are planed. I hope I have enough time to implement my ideas as soon
as possible! Version 0.40 will be the next full release.

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

It's possible to set the log level as string or as number. The default setting for
C<maxlevel> is C<warning> and the default setting for C<minlevel> is C<emergency>.

Example: If C<maxlevel> is set to C<warning> and C<minlevel> to C<emergency> then the
levels C<warning>, C<error>, C<critical>, C<alert> and C<emergency> would be logged.

You can set both to 8 or C<nothing> if you want to disable the logging machine.

=item B<timeformat>

The C<timeformat> is used for the placeholder C<%T>. You can set C<timeformat> with a
date and time format that is converted with C<POSIX::strftime>. The default format
is S<"%b %d %H:%M:%S"> and looks like

    Feb 01 12:56:31

As example the format S<"%Y/%m/%d %H:%M:%S"> would looks like

    2007/02/01 12:56:31

=item B<dateformat>

The same like C<timeformat>. It's useful if you want to split the date and time:

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

This helpful option appends a newline to the output message if a newline not exist.

    0 - disable (default)
    1 - enable - appends a newline to the log message if not exist

=item B<message_layout>

With this option you can define your own message layout with different placeholders
in C<printf()> style. The available placeholders are:

    %L   Log level
    %T   Time or full timestamp (option timeformat)
    %D   Date (option dateformat)
    %P   PID
    %H   Hostname
    %N   Newline
    %C   Caller - filename and line number
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

This option is just useful if you want to forward messages with L<Log::Handler::Output::Forward>
or insert the message with L<Log::Handler::Output::DBI> or dump messages to the screen with
L<Log::Handler::Output::Screen>.

Possible placeholders:

    %L   level
    %T   time
    %D   date
    %P   pid
    %H   hostname
    %N   newline
    %C   caller
    %p   progname
    %t   mtime
    %m   message

The option expects a array reference with a list of placeholders:

    message_pattern => [ qw/%T %L %H %m/ ]

The patterns are replaced with the pattern names as hash keys and the hash is passed
as reference to the output. Here a full code example:

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

With this option you can set the priority of your output objects. This means that messages
will be logged at first to the outputs with a higher priority. If this option is not set
then the default priority begins with 10 and will be increased +1 with each output. Example...

We add a output with no priority

    $log->add(file => { filename => 'file.log' });

This output gets the priority of 10. Now we add another output

    $log->add(file => { filename => 'file.log' });

This output gets the priority of 11... and so on.

Messages would be logged at first to priority 10 and then 11. Now you can add another output
and set the priority to 1.

    $log->add(screen => { dump => 1, priority => 1 });

Messages would be logged now at first to the screen.

=item B<die_on_errors>

Set C<die_on_errors> to 0 if you don't want that the handler die on failed write operations.

    0 - will not die on errors
    1 - will die (e.g. croak) on errors

If you set C<die_on_errors> to 0 then you have to controll it yourself.

    $log->info('info message') or die $log->errstr();

    # or Log::Handler->errstr()
    # or Log::Handler::errstr()
    # or $Log::Handler::ERRSTR

=item B<debug_trace>

You can activate a debugger that writes C<caller()> informations for each log level
that would logged. The debugger is logging all defined values except C<hints> and C<bitmask>.
Set C<debug_trace> to 1 to activate the debugger. The debugger is set to 0 by default.

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

The method C<add()> excepts 2 option parts; the options for the handler and for the
output module you want to use - the output modules got it's own documentation
for all options.

There are different ways to add a new output to the handler. The one way is that you create the
output object yourself and pass it with the handler options to C<add()>.

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

These thirteen methods could be very useful if you want to kwow if the current log level
would output the message. All methods returns TRUE if the current set of C<minlevel> and
C<maxlevel> would log the message and FALSE if not. Example:

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

For a full list take a look into the documentation of L<Log::Handler::Level>.

=head2 errstr()

Call C<errstr()> if you want to get the last error message. This is useful with
C<die_on_errors>. If you set C<die_on_errors> to C<0> the handler wouldn't croak
on failed write operations. Set C<die_on_errors> to control it yourself.

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

The exception is that the handler croaks in any case if the call of C<new()> or C<add()>
fails because on missing or wrong settings!

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

The default section - I call it section here - can be used to define default parameters
for all file outputs.

Take a look into the documentation of L<Log::Handler::Config> for more informations.

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

=head2 LOG VIA FILE

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
    $log->warning("this is a warning");
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
    Feb 01 12:56:31 [WARNING] this is a warning
    Feb 01 12:56:31 [ERROR] this is a error message
    Feb 01 12:56:31 [ERROR] this is a error message as well
    Feb 01 12:56:31 [CRITICAL] this is a critical message
    Feb 01 12:56:31 [CRITICAL] this is a critial message as well
    Feb 01 12:56:31 [ALERT] this is a alert message
    Feb 01 12:56:31 [EMERGENCY] this is a emergency message
    Feb 01 12:56:31 [EMERGENCY] this is a emergency message as well

=head2 LOG VIA DBI

    use Log::Handler;

    my $log = Log::Handler->new();

    $log->add(dbi => {
        # database connection
        database   => 'database',
        driver     => 'mysql',
        user       => 'user',
        password   => 'password',
        host       => '127.0.0.1',
        port       => 3306,
        debug      => 1,
        table      => 'messages',
        columns    => [ qw/level ctime cdate pid hostname caller progname mtime message/ ],
        values     => [ qw/%level %time %date %pid %hostname %caller %progname %mtime %message/ ],
        persistent => 1,
        reconnect  => 1,
        maxlevel   => 'error',
        minlevel   => 'emerg'
    });

    $log->error("this error goes to the database");

=head2 LOG VIA EMAIL

    use Log::Handler;

    my $log = Log::Handler->new();

    $log->add(email => {
        host     => 'mx.bar.example',
        hello    => 'EHLO my.domain.example',
        timeout  => 120,
        debug    => 1,
        from     => 'bar@foo.example',
        to       => 'foo@bar.example',
        subject  => 'your subject',
        buffer   => 100,
        interval => 60,
        maxlevel => 'error',
        minlevel => 'emerg',
    });

    $log->error($message);

=head2 LOG VIA FORWARD

    use Log::Handler;

    my $log = Log::Handler->new();

    $log->add(forward => {
        forward_to      => \&my_func,
        message_pattern => [ qw/%L %T %P %H %C %p %t/ ],
        message_layout  => '%m',
        maxlevel        => 'info',
    });

    $log->info('Hello World!');

    sub my_func {
        my $params = shift;
        print Dumper($params);
    }

=head2 LOG VIA SCREEN

    use Log::Handler;

    my $log = Log::Handler->new();

    $log->add(forward => {
        log_to          => 'STDERR',
        dump            => 1,
        message_pattern => [ qw/%L %T %P %H %C %p %t/ ],
        message_layout  => '%m',
        maxlevel        => 'info',
    });

    $log->info('Hello World!');

=head2 DIFFERENT OUTPUTS

    use Log::Handler;

    # create the log handler object
    my $log = Log::Handler->new();

    $log->add(file => {
        filename => 'debug.log',
        mode     => 'append',
        maxlevel => 7,
        minlevel => 7,
    });

    $log->add(file => {
        filename => 'common.log',
        mode     => 'append',
        maxlevel => 6,
        minlevel => 5,
    });

    $log->add(file => {
        filename => 'error.log',
        mode     => 'append',
        maxlevel => 4,
        minlevel => 0,
    });

    # log to debug.log
    $log->debug("this is a debug message");

    # log to common.log
    $log->info("this is a info message");
    $log->notice("this is a notice");

    # log to error.log
    $log->warning("this is a warning");
    $log->error("this is a error message");
    $log->err("this is a error message as well");
    $log->critical("this is a critical message");
    $log->crit("this is a critical message as well");
    $log->alert("this is a alert message");
    $log->emergency("this is a emergency message");
    $log->emerg("this is a emergency message as well");

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

    * Log::Handler::Output::Socket

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
our $VERSION  = '0.38_14';
our $ERRSTR   = '';
our $PRIORITY = 10;

use Carp;
use POSIX;
use Params::Validate;
use UNIVERSAL::require;
use Log::Handler::Output;
use Log::Handler::Config;
use base qw(Log::Handler::Levels);

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

my %AVAILABLE_OUTPUTS = (
    file    => 'Log::Handler::Output::File',
    email   => 'Log::Handler::Output::Email',
    forward => 'Log::Handler::Output::Forward',
    dbi     => 'Log::Handler::Output::DBI',
    screen  => 'Log::Handler::Output::Screen',
);

# save all loaded outputs here
my %LOADED_MODULES = ();

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

    my $progname = $0;
    $progname =~ s@.*[/\\]@@;

    my %pattern = (
        '%L'  => {  name => 'level',
                    code => sub { $Log::Handler::Output::LEVEL } },
        '%T'  => {  name => 'time',
                    code => sub { POSIX::strftime(shift->{timeformat}, localtime) } },
        '%D'  => {  name => 'date',
                    code => sub { POSIX::strftime(shift->{dateformat}, localtime) } },
        '%P'  => {  name => 'pid',
                    code => sub { $$ } },
        '%H'  => {  name => 'hostname',
                    code => \&Sys::Hostname::hostname },
        '%N'  => {  name => 'newline',
                    code => "\n" },
        '%C'  => {  name => 'caller',
                    code => sub { my @c = caller($Log::Handler::Output::CALLER); "$c[1], line $c[2]" } },
        '%p'  => {  name => 'progname',
                    code => sub { $progname } },
        '%t'  => {  name => 'mtime',
                    code => \&Log::Handler::Output::_measurement },
        '%m'  => {  name => 'message',
                    code => sub { $Log::Handler::Output::MESSAGE } },
    );

    my $self = bless {
        pattern    => \%pattern,
        priorities => { },
        levels     => { },
    }, $class;

    if (@_) {
        # for backward compatibilities
        $self->add(file => @_);
    }

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

sub errstr { $ERRSTR }

#
# private stuff
#

sub _shift_options {
    my ($self, $options) = @_;
    my %output_opts;

    my @output_options = qw(
        timeformat
        prefix
        message_layout
        message_pattern
        newline
        minlevel
        maxlevel
        die_on_errors
        priority
        debug_trace
        debug_mode
        debug_skip
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

        if (!$LOADED_MODULES{$package}) {
            $package->require;
            $LOADED_MODULES{$package} = 1;
        }

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
        prefix => {
            type => Params::Validate::SCALAR,
            optional => 1,
        },
        message_layout => {
            type => Params::Validate::SCALAR,
            default => '%T [%L] %m',
        },
        message_pattern => {
            type => Params::Validate::SCALAR | Params::Validate::ARRAYREF,
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
    });

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

    if ($options{prefix}) {
        $options{message_layout}  =  $options{prefix};
        $options{message_layout}  =~ s/<--LEVEL-->/%L/g;
        $options{message_layout} .=  '%m';
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
                next; # the message is builded ever
            }
            my $name = $pattern->{$_}->{name};
            my $code = $pattern->{$_}->{code};
            $options{pattern}{$name} = $code;
        }
    }

    return \%options;
}

sub _raise_error {
    my $self = shift;
    $ERRSTR = shift;
    return undef;
}

1;
