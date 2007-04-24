=head1 NAME

Log::Handler - A simple handler to log messages to log files.

=head1 SYNOPSIS

    use Log::Handler;
    # or
    use Log::Handler debug => 1;
    # or
    use Log::Handler debug => 2;

    my $log = Log::Handler->new( filename => $logfile, mode => 'append' );

    $log->alert("foo bar");

=head1 DESCRIPTION

This module is just a simple log file handler. It's possible to define a log level
for your programs and control the amount of informations that be logged to the log
file. In addition it's possible to define how you wish to open the log file,
transient or permanent and if you wish you can assign the handler to check the
inode of the log file. This could be very useful if a rotate mechanism moves
and zip the log file but you shouldn't forget that inodes aren't available on
windows.

=head1 CHANGES FROM 0.11

The log level numbers changed because they wasn't in the right order!

    8 nothing   is still the same
    7 emergency is now 0
    6 alert     is now 1
    5 crit      is now 2
    4 error     is now 3
    3 warning   is now 4
    2 notice    is now 5
    1 info      is now 6
    0 debug     is now 7

If you set C<minlevel> and C<maxlevel> as strings in earlier versions then you don't need
to change your code, but if you used numbers then you have to change it!

=head1 METHODS

=head2 new()

Call C<new()> to create a new log handler object.

The C<new()> method expected the options for the log file. The only one mandatory
option is C<filename>. All other options will be set to a default value.

=head2 set_prefix()

Call C<set_prefix()> to modifier the option prefix after you called C<new()>.

    my $log = Log::Handler->new(
       filename => 'file.log',
       mode => 'append',
       prefix => "myhost:$$ [<--LEVEL-->] "
    );

    $log->set_prefix("[<--LEVEL-->] myhost:$$ ");

=head2 get_prefix()

Call C<get_prefix()> to get the current prefix if you just want to modifier the current
prefix and re-set the old.

    # safe the old prefix
    my $old_prefix = $log->get_prefix();

    # set a new one for a code part in your script
    $log->set_prefix("my new prefix");

    # now set the your old prefix again
    $log->set_prefix($old_prefix);

Or you want to add something to the current prefix:

    $log->set_prefix($log->get_prefix."add something");

=head2 Log levels

There are eigth log level and twelve methods to handle this levels:

=over 4

=item emergency(), emerg()

=item alert()

=item critical(), crit()

=item error(), err()

=item warning()

=item notice(), note()

=item info()

=item debug()

=back

C<debug()> is the highest and C<emergency()> or C<emerg()> is the lowest log level.
You can define the log level with the options C<maxlevel()> and C<minlevel()>.

The methods C<note()>, C<err()>, C<crit()> and C<emerg()> are just shortcuts.

Example:

If you set the option C<maxlevel> to C<warning> and C<minlevel> to C<emergency>
then the levels emergency, alert, critical, error and warning will be logged.

The call of all methods is very simple:

    $log->info("Hello World! How are you?");

Or maybe:

    $log->info("Hello World!", "How are you?");

Both calls would log (provided that the log level INFO would log)

    Feb 01 12:56:31 [INFO] Hello World! How are you?

=head2 would_log_* methods

=over 4

=item would_log_emergency(), would_log_emerg()

=item would_log_alert()

=item would_log_critical(), would_log_crit()

=item would_log_error(), would_log_err()

=item would_log_warning()

=item would_log_notice(), would_log_note()

=item would_log_info()

=item would_log_debug()

=back

This twelve methods could be very useful if you want to kwow if the current log level
would log the message to the log file. All methods returns TRUE if the handler would
log the message and FALSE if not. Example:

You want to dump a big hash with Data::Dumper to the log file, but you don't want to
pass the dump in any case, because it would costs a lot of resources.

    $log->debug(Dumper($hash));

This example would dump the $hash in any case and handoff it to the log handler, 
but this isn't that what we really want!

    $log->debug(Dumper($hash))
       if $log->would_log_debug();

Now we dump the $hash only if the current log level would really log it.

The methods C<would_log_note()>, C<would_log_err()>, C<would_log_crit()> and
C<would_log_emerg()> are just shortcuts.

All methods that would NOT log the message returns TRUE.

=head2 errstr()

Call C<errstr()> if you want to get the last error string. This is useful with the
option C<die_on_errors>. If you set this option to 0 the handler wouldn't croak
if simple write operations failed. Set C<die_on_errors> to control it yourself.
C<errstr()> is only useful with C<new()>, C<CLOSE()> and the log level methods.

    $log->info("log information") or die $log->errstr;

Or

    $error_string = $log->errstr
       unless $log->info("log some informations");

The error string contains C<$!> in parantheses at the end of the error string.

The exception is that the handler croaks in any case if the call of C<new()> failed
because on missing params or on wrong settings!

    my $log = Log::Handler->new(filename => 'file.log', mode => 'foo bar');

This would croaks, because option C<mode> except C<append> or C<trunc> or C<excl>.

If you set the option C<fileopen> to 1 - the default - to open the log file permanent
and the call of C<new> failed then you can absorb the error.

    my $log = Log::Handler->new(filename => 'file.log')
       or warn Log::Handler->errstr;

=head2 CLOSE()

Call C<CLOSE()> if you want to close the log file.

This option is only useful if you set option C<fileopen> to 1. If you don't
call C<CLOSE()> the log file will be closed automatically before exit().

Note that if you close the log file it's necessary to call C<new()> to reopen it.

=head1 OPTIONS

=head2 filename

This is the only one mandatory option and the script croak if it not set. You have to
set a filename, a GLOBREF or you can set a string as an alias for STDOUT and STDERR.

Set a file name:

    $log = Log::Handler->new( filename => 'file.log'  );

Set a file handle

    open my $fh, '>', 'file.log' or die $!;
    $log = Log::Handler->new( filename => $fh );

Set a GLOBREF

    open FH, '>', 'file.log' or die $!;
    $log = Log::Handler->new( filename => \*FH );

Set STDOUT or STDERR

    $log = Log::Handler->new( filename => \*STDOUT );
    $log = Log::Handler->new( filename => \*STDERR );

If the option C<filename> is set in a config file and you want to debug to your screen then
you can set C<*STDOUT> or C<*STDERR> as a string.

    my $out = '*STDOUT';
    $log = Log::Handler->new( filename => $out );
    $log = Log::Handler->new( filename => '*STDOUT' );
    $log = Log::Handler->new( filename => '*STDERR' );

That is not possible:

    $log = Log::Handler->new( filename => '*FH' );

Note that if you set a GLOBREF to C<filename> some options will be forced (overwritten)
and you have to control the handles yourself. The forced options are

    fileopen => 1
    filelock => 0
    reopen   => 0

=head2 filelock

It's maybe desirable to lock the log file by each write operation. You can set the option
C<filelock> to activate or deactivate the locking.

    0 - no file lock
    1 - exclusive lock (LOCK_EX) and unlock (LOCK_UN) by each log message (default)

=head2 fileopen

Open a log file transient or permanent.

    0 - open and close the logfile by each write operation (default)
    1 - open the logfile if C<new()> called and try to reopen the
        file if reopen is set to 1 and the inode of the file has changed

=head2 reopen

This option works only if option C<fileopen> is set to 1.

    0 - deactivate
    1 - try to reopen logfile if the inode changed (default)

=head2 filename and reopen

Please note that it's better to set C<reopen> and C<filename> to 0 on Windows systems
because Windows unfortunately haven't the faintest idea of inodes.

To write your code independent you should control that:

    my $os_is_win = $^O =~ /win/i ? 0 : 1;

    my $log = Log::Handler->new(
       filename => 'file.log',
       mode => 'append',
       fileopen => $os_is_win
    );

To set C<filename> to 0 implies that C<reopen> has no importance.

=head2 mode

There are three possible modes to open a log file.

    append - O_WRONLY | O_APPEND | O_CREAT
    excl   - O_WRONLY | O_EXCL   | O_CREAT (default)
    trunc  - O_WRONLY | O_TRUNC  | O_CREAT

C<append> would open the log file in any case and appends the messages at
the end of the log file.

C<excl> would fail to open the log file if the log file already exists.
If the log file doesn't exist it will be created.

C<trunc> would truncate the complete log file if it exist. Please take care
to use this option!

Take a look to the documentation of C<sysopen()> to get more informations
and take care to use C<append> or C<trunc>!

=head2 autoflush

    0 - autoflush off
    1 - autoflush on (default)

=head2 permissions

C<permissions> sets the permission of the file if it creates and must be set
as a octal value. These permission values need to be in octal and are modified
by your process's current "umask".

This means that you have to use the unix style permissions such as C<chmod>.
C<0640> is the default permission for this option. That means that the owner got
read and write permissions and users in the same group got only read permissions.
All other users got no access.

Take a look to the documentation of C<sysopen()> to get more informations.

=head2 timeformat

You can set C<timeformat> with a date and time format that will be coverted
by POSIX::strftime(). The default format is "%b %d %H:%M:%S" and looks like

    Feb 01 12:56:31

As example the format "%Y/%m/%d %H:%M:%S" would looks like

    2007/02/01 12:56:31

=head2 newline

This helpful option appends a newline to the log message if not exist.

    0 - deactivated (default)
    1 - appends a newline to the log message if not exist

=head2 prefix

Set C<prefix> to define your own prefix for each message. The default value
is "[<--LEVEL-->] ".

"<--LEVEL-->" is replaced with the current message level. Default example:

    $log->alert("message ...");

would log

    Feb 01 12:56:31 [ALERT] message ...

If you set C<prefix> to

    prefix => 'foo <--LEVEL--> bar: '

    $log->info("foobar");

then it would log

    Feb 01 12:56:31 foo INFO bar: foobar

Take a look to the EXAMPLES to see more.

=head2 maxlevel and minlevel

With the options C<maxlevel> and C<minlevel> you can set the log levels you
wish to log to your log file. The log levels are:

    7 - debug
    6 - info
    5 - notice, note
    4 - warning
    3 - error, err
    2 - critical, crit
    1 - alert
    0 - emergency, emerg

The levels C<note>, C<err>, C<crit> and C<emerg> are just shortcuts.

It's possible to set the log level as a string or as number. The default
C<maxlevel> is 4 and the default C<minlevel> is 0.

Example: If C<maxlevel> is set to 4 and C<minlevel> to 0 then only emergency (emerg),
alert, critical (crit) and error (err) messages will be logged to the log file.

You can set both to 8 or "nothing" if you don't want to log any message.

=head2 die_on_errors

Set C<die_on_errors> to 0 if you don't want that the handler croaks if normal
operations failed.

    0 - will not die on errors
    1 - will die (e.g. croak) on errors

The exception is that the handler croaks in any case if the call of C<new()> failed
because on missing params or wrong settings.

=head1 DEBUG MODE

You can activate a simple debugger to log C<caller()> informations by each log operation.
There are two debug modes: block(1) and line(2) mode.

The block mode looks like this:

    use strict;
    use warnings;
    use Log::Handler debug => 1;

    my $log = Log::Handler->new(
       filename => \*STDOUT,
       maxlevel => 'debug'
    );

    &test2;

    sub test1 {
       $log->debug();
    }

    sub test2 {
       &test1;
    }

Output:

    Apr 20 13:42:21 [DEBUG] 
       CALL(0):
          filename    /usr/local/share/perl/5.8.8/Log/Handler.pm
          hasargs     1
          line        631
          package     Log::Handler
          subroutine  Log::Handler::_print
       CALL(1):
          filename    ./test.pl
          hasargs     1
          line        14
          package     main
          subroutine  Log::Handler::__ANON__
       CALL(2):
          filename    ./test.pl
          hasargs     0
          line        18
          package     main
          subroutine  main::test1
       CALL(3):
          filename    ./test.pl
          hasargs     0
          line        11
          package     main
          subroutine  main::test2

The same code example but the debugger in line mode would looks like this:

    use Log::Handler debug => 2;

Output:

    Apr 20 13:47:59 [DEBUG] 
       CALL(0): filename(/usr/local/share/perl/5.8.8/Log/Handler.pm) hasargs(1) line(631) package(Log::Handler) subroutine(Log::Handler::_print)
       CALL(1): filename(./test.pl) hasargs(1) line(14) package(main) subroutine(Log::Handler::__ANON__)
       CALL(2): filename(./test.pl) hasargs(0) line(18) package(main) subroutine(main::test1)
       CALL(3): filename(./test.pl) hasargs(0) line(11) package(main) subroutine(main::test2)

=head1 EXAMPLES

=head2 Simple example to log all level:

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
    $log->error("this is a error message");
    $log->err("this is a error message as well");
    $log->critical("this is a critical message");
    $log->crit("this is a critical message as well");
    $log->alert("this is a alert message");
    $log->emergency("this is a emergency message");
    $log->emerg("this is a emergency message as well");

Would log this:

    Feb 01 12:56:31 [DEBUG] this is a debug message
    Feb 01 12:56:31 [INFO] this is a info message
    Feb 01 12:56:31 [NOTICE] this is a notice
    Feb 01 12:56:31 [NOTE] this is a notice as well
    Feb 01 12:56:31 [WARNING] this is a warning
    Feb 01 12:56:31 [ERROR] this is a error message
    Feb 01 12:56:31 [ERR] this is a error message as well
    Feb 01 12:56:31 [CRITICAL] this is a critical message
    Feb 01 12:56:31 [CRIT] this is a critial message as well
    Feb 01 12:56:31 [ALERT] this is a alert message
    Feb 01 12:56:31 [EMERGENCY] this is a emergency message
    Feb 01 12:56:31 [EMERG] this is a emergency message as well

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

    $log->note("$$");

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
       prefix   => "${hostname}[$pid] [<--LEVEL-->] $progname: "
    );

    $log->info("Hello World!");
    $log->warning("There is something wrong!");

Would log:

    Feb 01 12:56:31 hostname[8923] [INFO] progname: Hello world
    Feb 01 12:56:31 hostname[8923] [WARNING] progname: There is something wrong!

=head2 would_log_* example:

    use Log::Handler;
    use Data::Dumper;

    my $log = Log::Handler->new(
       filename   => 'file1.log',
       mode       => 'trunc',
       maxlevel   => 4,
       prefix     => '',
       timeformat => ''
    );

    my %hash = (
        foo => 1,
        bar => 2
    );

    $log->debug("\n".Dumper(\%hash))
        if $log->would_log_debug();

Would NOT dump %hash to the $log object!

=head2 die_on_errors example:

    use Log::Handler;
    use Data::Dumper;

    my $log = Log::Handler->new(
       filename      => 'file1.log',
       mode          => 'append',
       die_on_errors => 0
    ) or die Log::Handler->errstr();

    if ($log->would_log_debug()) {
       $log->debug("\n".Dumper(\%hash))
          or die $log->errstr();
    }

=head1 DEPENDENCIES

    strict            -  to restrict unsafe constructs
    warnings          -  to control optional warnings
    Fcntl             -  for flock(), O_APPEND, O_WRONLY, O_EXCL and O_CREATE
    IO::Handle        -  to set autoflush on the log file handle
    File::stat        -  to get the inode from the log file
    POSIX             -  to generate the time stamp with strftime()
    Params::Validate  -  to validate all options
    Carp              -  to croak() on errors if die_on_errors is active

=head1 EXPORTS

No exports.

=head1 REPORT BUGS

Please report all bugs to <jschulz.cpan(at)bloonix.de>.

=head1 AUTHOR

Jonny Schulz <jschulz.cpan(at)bloonix.de>.

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

our $VERSION = '0.14';

use strict;
use warnings;
use Fcntl qw( :flock O_WRONLY O_APPEND O_TRUNC O_EXCL O_CREAT );
use IO::Handle;
use File::stat;
use POSIX qw(strftime);
use Params::Validate;
use Carp qw(croak);

use constant EMERGENCY =>  0;
use constant EMERG     =>  0;
use constant ALERT     =>  1;
use constant CRITICAL  =>  2;
use constant CRIT      =>  2;
use constant ERROR     =>  3;
use constant ERR       =>  3;
use constant WARNING   =>  4;
use constant NOTICE    =>  5;
use constant NOTE      =>  5;
use constant INFO      =>  6;
use constant DEBUG     =>  7;
use constant NOTHING   =>  8;

# The BEGIN block is used to generate the syslog methods
# and the would_log_* methods. The syslog methods calls
# _print() with the syslog level as first argument. The
# would_log_*() methods are only used to check if the
# current set of max- and minlevel would log the message
# to the log file. The levels NOTE, ERR, CRIT and EMERG
# are just shortcuts.

BEGIN {
   for my $level (qw(DEBUG INFO NOTICE NOTE WARNING ERROR ERR CRITICAL CRIT ALERT EMERGENCY EMERG)) {
      my $routine = lc($level);
      {  # start "no strict" block
         no strict 'refs';

         # syslog level methods
         *{"$routine"} = sub {
            my $self = shift;
            return $self->_print($level, @_);
         };

         # would log syslog methods
         *{"would_log_$routine"} = sub {
            my $self = shift;
            return 1
               if &{$level} >= $self->{minlevel}
               && &{$level} <= $self->{maxlevel};
            return undef;
         };
      } # end "no strict" block
   }
}

sub import {
   my ($package, %args) = @_;
   croak "$package: set debug to 1 or 2 to activate the debugger"
      if $args{debug}
      && $args{debug} !~ /^[12]$/;
   $Log::Handler::DEBUGGER = $args{debug};
}

sub new {
   my $class = shift;
   my %opts  = ();
   my $self  = bless \%opts, $class;
   my $bool  = qr/^[10]$/;

   %opts = Params::Validate::validate(@_, {
      filename => {
         type => Params::Validate::SCALAR | Params::Validate::GLOBREF,
      },
      filelock => {
         type => Params::Validate::SCALAR,
         regex => $bool,
         default => 1,
      },
      fileopen => {
         type => Params::Validate::SCALAR,
         regex => $bool,
         default => 1,
      },
      reopen => {
         type  => Params::Validate::SCALAR,
         regex => $bool,
         default => 1,
      },
      mode => {
         type => Params::Validate::SCALAR,
         regex => qr/^(append|excl|trunc)$/,
         default => 'excl',
      },
      autoflush => {
         type => Params::Validate::SCALAR,
         regex => $bool,
         default => 1,
      },
      permissions => {
         type => Params::Validate::SCALAR,
         regex => qr/^[0-7]{3,4}$/,
         default => '0640',
      },
      timeformat => {
         type => Params::Validate::SCALAR,
         default => '%b %d %H:%M:%S',
      },
      newline => {
         type => Params::Validate::SCALAR,
         regex => $bool,
         default => 0,
      },
      prefix => {
         type => Params::Validate::SCALAR,
         default => '[<--LEVEL-->] ',
      },
      minlevel => {
         type => Params::Validate::SCALAR,
         regex => qr/^([0-8]|nothing|debug|info|notice|note|warning|error|err|critical|crit|alert|emergency|emerg)$/,
         default => 0,
      },
      maxlevel => {
         type => Params::Validate::SCALAR,
         regex => qr/^([0-8]|nothing|debug|info|notice|note|warning|error|err|critical|crit|alert|emergency|emerg)$/,
         default => 4,
      },
      die_on_errors => {
         type => Params::Validate::SCALAR,
         regex => $bool,
         default => 1,
      },
   });

   {  # start "no strict" block
      no strict 'refs';
      $opts{minlevel} = &{uc($opts{minlevel})}
         unless $opts{minlevel} =~ /^\d+$/;
      $opts{maxlevel} = &{uc($opts{maxlevel})}
         unless $opts{maxlevel} =~ /^\d+$/;
   } # end "no strict" block

   # if option filename is a GLOB, then we force some options
   if (ref($opts{filename}) eq 'GLOB') {
      $opts{fh} = $opts{filename};
   } elsif ($opts{filename} eq '*STDOUT') {
      $opts{fh} = \*STDOUT;
   } elsif ($opts{filename} eq '*STDERR') {
      $opts{fh} = \*STDERR;
   }

   if (defined $opts{fh}) {
      $opts{fileopen} = 1;
      $opts{reopen}   = 0;
      $opts{filelock} = 0;
      $opts{fh}->autoflush($opts{autoflush});
      return $self;
   }

   if ($opts{mode} eq 'append') {
      $opts{mode} = O_WRONLY | O_APPEND | O_CREAT;
   } elsif ($opts{mode} eq 'excl') {
      $opts{mode} = O_WRONLY | O_EXCL | O_CREAT;
   } elsif ($opts{mode} eq 'trunc') {
      $opts{mode} = O_WRONLY | O_TRUNC | O_CREAT;
   }

   $opts{permissions} = oct($opts{permissions});

   # open the log file permanent
   if ($opts{fileopen} == 1) {
      $self->_open()
         or return undef;
      $self->_setino()
         if $opts{reopen} == 1;
   }

   return $self;
}

sub get_prefix {
   my $self = shift;
   return $self->{prefix};
}

sub set_prefix {
   my $self = shift;
   $self->{prefix} = shift;
}

sub CLOSE {
   my $self = shift;

   if ($self->{fileopen} == 1) {
      $self->_close()
         or return undef;
   }

   return 1;
}

# to make it possible to call Log::Handler->errstr()
sub errstr { $Log::Handler::ERRSTR }

sub DESTROY {
   my $self = shift;
   close($self->{fh})
      if $self->{fh}
      && !ref($self->{filename})
      && $self->{filename} !~ /^\*STDOUT$|^\*STDERR$/;
}

#
# private stuff
#

sub _open {
   my $self  = shift;
   my $class = ref($self);

   return $self->_raise_error("unable to open logfile $self->{filename} ($!)")
      unless sysopen(my $fh, $self->{filename}, $self->{mode}, $self->{permissions});

   $self->{fh} = $fh;
   $self->{fh}->autoflush($self->{autoflush});

   return 1;
}

sub _close {
   my $self  = shift;
   my $class = ref($self);

   return $self->_raise_error("unable to close logfile $self->{filename} ($!)")
      unless close $self->{fh};

   delete $self->{fh};

   return 1;
}

sub _setino {
   my $self  = shift;
   my $class = ref($self);
   my $stat  = stat($self->{filename});
   $self->{inode} = $stat->ino;
   return 1;
}

sub _checkino {
   my $self  = shift;
   my $class = ref($self);

   if (-e "$self->{filename}") {
      my $stat    = stat($self->{filename});
      my $new_ino = $stat->ino;

      unless ($self->{inode} == $new_ino) {
         $self->_close()
            or return undef;
         $self->_open()
            or return undef;
         $self->{inode} = $new_ino;
      }
   } else {
      $self->_close()
         or return undef;
      $self->_open()
         or return undef;
      $self->_setino()
         if $self->{reopen} == 1;
   }

   return 1;
}

sub _lock {
   my $self  = shift;
   my $class = ref($self);

   return $self->_raise_error("unable to lock logfile $self->{filename} ($!)")
      unless flock($self->{fh}, LOCK_EX);

   return 1;
}

sub _unlock {
   my $self  = shift;
   my $class = ref($self);

   return $self->_raise_error("unable to unlock logfile $self->{filename} ($!)")
      unless flock($self->{fh}, LOCK_UN);

   return 1;
}

sub _print {
   my $self  = shift;
   my $level = shift;
   my $class = ref($self);

   {  # return if we don't want log this level
      no strict 'refs';
      return 1
         unless &{$level} >= $self->{minlevel}
             && &{$level} <= $self->{maxlevel};
   }

   if ($self->{fileopen} == 0) {
      $self->_open()
         or return undef;
   } elsif ($self->{reopen} == 1) {
      $self->_checkino()
         or return undef;
   }

   if ($self->{filelock} == 1) {
      $self->_lock()
         or return undef;
   }

   my $message = ();

   if ($self->{timeformat}) {
      $message .= $self->_gettime()
         or return undef;
      $message .= ' ';
   }

   if (length($self->{prefix}) > 0) {
      my $prefix = $self->{prefix};
      $prefix =~ s/<--LEVEL-->/$level/g;
      $message .= $prefix;
   }

   $message .= join(' ', @_)
      if @_;

   $message .= "\n" # I hope that this works on the most OSs
      if $self->{newline}
      && $message =~ /.*\z/m;

   if ($Log::Handler::DEBUGGER) {
      my $i = -1;
      $message .= "\n" if $message =~ /.*\z/m;
      for (;;) {
         my %c;
         @c{qw/package filename line subroutine hasargs
               wantarray evaltext is_require/} = (caller(++$i))[0..7];
         last unless $c{package};
         $message .= ' ' x 3 . "CALL($i):";
         foreach my $k (sort keys %c) {
            next unless defined $c{$k};
            if ($Log::Handler::DEBUGGER == 1) {
               $message .= "\n" . ' ' x 6 . sprintf('%-12s', $k) . "$c{$k}";
            } elsif ($Log::Handler::DEBUGGER == 2) {
               $message .= " $k($c{$k})";
            }
         }
         $message .= "\n";
      }
   }

   my $length  = length($message);
   my $written = syswrite($self->{fh}, $message, $length)
      or return $self->_raise_error("unable to write to logfile ($!)");

   return $self->_raise_error("$written/$length bytes written to logfile $self->{filename} ($!)")
      unless $length == $written;

   if ($self->{filelock} == 1) {
      $self->_unlock()
         or return undef;
   }

   if ($self->{fileopen} == 0) {
      $self->_close()
         or return undef;
   }

   return 1;
}

sub _gettime {
   my $self = shift;
   my $time = strftime($self->{timeformat}, localtime)
      or return $self->_raise_error("unable to set time stamp ($!)");
   return $time;
}

sub _raise_error {
   my $self   = shift;
   my $class  = ref($self);
   my $errstr = defined $_[0] ? $_[0] : '';
   $Log::Handler::ERRSTR = $errstr;
   croak "$class: $errstr" if $self->{die_on_errors} == 1;
   return undef;
}

1;
