#
# Module by Dave Rolsky (grimes@waste.org)
#
# Copyright (c) 1998 David Rolsky. All rights reserved.
# This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#
#

package Log::Handler;  #Not the final name!

use FileHandle;
use Carp;

use strict;
use vars qw[$VERSION $SENDMAIL $LH_ERROR];

$VERSION = '0.30';

$LH_ERROR = FileHandle::new FileHandle (">lh_int_error.$$") or carp ("can't create file lh_int_error.$$");

my $mail = 0;

if (not $mail)
{
    eval "use Mail::Send;";
    unless ($@)
    {
	$mail = 1;
	$SENDMAIL = \&_mail_send;
    }
}

if (not $mail)
{
    eval "use Mail::Sendmail;";
    unless ($@)
    {
	$mail = 1;
	$SENDMAIL = \&_mail_sendmail;
    }
}

if (not $mail)
{
    my @possible_dirs = qw(
			   /usr/lib
			   /bin
			   /usr/bin
			   /usr/local/bin
			   /usr/local/mail/bin
			   /usr/local/lib/mail/bin
			   /sbin
			   /usr/sbin
			   /usr/local/sbin
			   );
    
    foreach my $dir (@possible_dirs)
    {
	if (-s "$dir/sendmail" && -x "$dir/sendmail")
	{
	    my $executable = "$dir/sendmail";
	    
	    $SENDMAIL = sub
	    {
		my ($err_msg, $addresses) = @_;
		
		my $recipients = join (',', @$addresses);

		unless (open (SENDMAIL, "| $executable '$recipients'"))
		{
		    print $LH_ERROR ("unable to write to $executable\n$!\n");
		    carp ("unable to write to $executable\n$!\n");
		    return -1;
		}
		
		print SENDMAIL << "EOMAIL";
To: $recipients
X-True-Sender: Log::Handler.pm called by $0
Subject: An error has occurred while running $0.  See body for details.

$err_msg

EOMAIL
            }
	}
	$mail = 1;
	last;
    }
}

$SENDMAIL = undef if (not $mail);

1;

sub new
{
    my $class  = shift;
    my $leave_zero = 0;

    if (defined $_[2])
    {
	$leave_zero = $_[2];
    }

    my $email_addresses = {};  #names to addresses
    my $log  = {};             #names to file names (with modes)

    if (not (values %{$_[0]} || values %{$_[1]} ) )
    {
	croak ("Log::Handler usage:\n\$lh = new Log::Handler ({'name'=>'someone\@somewhere.net'},{log=>'log.txt'});\n\nYou must provide at least one email address or one file name to Log::Handler.\n\n");
    }

    $email_addresses = $_[0];

    ($log, $leave_zero) = &_can_write ($_[1], $leave_zero);

    if (not (%$email_addresses || %$log) )
    {
	croak ("no email addresses or usable files unto which to direct error messages\n");
    }

    return bless {
	'email'  => $email_addresses,
	'log'    => $log,
	'leave'  => $leave_zero,
	}, $class;
}

sub DESTROY
{
    my ($self) = @_;

    exit if ( (not ref ($self->{'leave'}) &&
	       ($self->{'leave'}) ) );

    if ($self->{'log'})
    {
	foreach (keys %{$self->{'log'}})
	{
	    my $name = $self->{'log'}->{$_}->{'name'};

	    next if ($name eq "\0\0");
	    next if ($self->{'leave'}->{$_});

	    close $self->{'log'}->{$_}->{'fh'};

	    unless (-s $name)
	    {
		unless (unlink ($self->{'log'}->{$_}->{'name'}))
		{
		    carp "unable to delete $self->{'log'}->{$_}->{'name'}\n$!\n";
		    print $LH_ERROR "unable to delete $self->{'log'}->{$_}->{'name'}\n$!\n";
		}
	    }
	}
    }

    close $LH_ERROR;

    unless (-s "lh_int_error.$$")
    {
	unlink ("lh_int_error.$$")
	    || carp "unable to delete lh_int_error.$$\n$!\n";
    }

}

sub lhdie
{
    my ($self, $msg, $people, $files, $screen) = @_;

    $screen = 0 if (not defined $screen);

    &_process_message ($self, $msg, $people, $files, $screen, 1);
}

sub lhwarn
{
    my ($self, $msg, $people, $files, $screen) = @_;

    $screen = 0 if (not defined $screen);

    &_process_message ($self, $msg, $people, $files, $screen, 0);
}

sub log
{
    lhwarn (@_);
}

sub open
{
    my ($self, $files) = @_;

    foreach (@$files)
    {
	if ($self->{'log'}->{$_}->{'name'} eq "\0\0")
	{
	    print $LH_ERROR ("Log::Handler->open: can't open user provided object!\n");
	    carp ("Log::Handler->open: can't open user provided object!\n");
	    next;
	}

	my $filename = $self->{'log'}->{$_}->{'name'};

	my $temp_fh = FileHandle::new FileHandle;

	unless (open ($temp_fh, ">>$filename"))
	{
	    print $LH_ERROR ("unable to open $files->{$_}.\n$!\n");
	    carp ("unable to open $files->{$_}.\n$!\n");
	    next;
	}

	$self->{'log'}->{$_}->{'fh'} = $temp_fh;
    }
}

sub close
{
    my ($self, $files) = @_;

    foreach (@$files)
    {
	if ($self->{'log'}->{$_}->{'name'} eq "\0\0")
	{
	    print $LH_ERROR ("Log::Handler->close: can't close user provided object!\n");
	    carp ("Log::Handler->close: can't close user provided object!\n");
	    next;
	}

	my $temp_fh = $self->{'log'}->{$_}->{'fh'};

	close $temp_fh;
    }
}

sub _process_message
{
    my ($self, $msg, $people, $files, $screen, $fatal) = @_;
    my (@addresses, @handles);

    if ( (not defined $people) || ($people && not (($people eq '0') || ($people eq ''))))
    {
	if ($self->{'email'})
	{
	    if (ref $people eq 'ARRAY')
	    {
		foreach (@$people)
		{
		    push (@addresses, $self->{'email'}->{$_});
		}
	    }
	    else
	    {
		@addresses = values %{$self->{'email'}};
	    }

	    &$SENDMAIL ($msg, \@addresses);
	}
	else
	{
	    carp ("You can't send email without defining email recipients when the object is created!\n");
	}
    }

    if ( (not defined $files) || ($files && not ($files eq '0' || $files eq '')))
    {
	if ($self->{'log'})
	{
	    if (ref $files eq 'ARRAY')
	    {
		foreach (@$files)
		{
		    push (@handles, $self->{'log'}->{$_}->{'fh'});
		}
	    }
	    else
	    {
		foreach (keys %{$self->{'log'}})
		{
		    push (@handles, $self->{'log'}->{$_}->{'fh'});
		}
	    }

	    &_log_error ($msg, \@handles);
	}
	else
	{
	    carp ("You can't write to files without defining them first during object creation!\n");
	}
    }

    if ($screen)
    {
	print STDOUT $msg;
    }

    if ($fatal)
    {
	croak ($msg);
    }
}

sub _mail_send
{
    my ($msg, $addresses) = @_;

    no strict 'subs';
    $mail = Mail::Send::new Mail::Send;
    use strict 'subs';

    my $recipients = join (',', @$addresses);

    $mail->to($recipients);
    $mail->subject("Subject: An error has occurred while running $0.  See body for details.");
    $mail->add("X-True-Sender", "X-True-Sender: Log::Handler.pm called by $0
");

    my $handle = $mail->open;

    print $handle "\n$msg\n";

    $handle->close;
}

sub _mail_sendmail
{
    my ($msg, $addresses) = @_;

    my $recipients = join (',', @$addresses);

    my %mail = (
		To      => $recipients,
		Subject => "Subject: An error has occurred while running $0.  See body for details",
		Message => "\n$msg\n"
		);
    
    if (&sendmail (%mail))
    {
	print $LH_ERROR "unable to send with Mail::Sendmail module.\n$!\n";
	carp "unable to send with Mail::Sendmail module.\n$!\n";
    }
}

sub _log_error
{
    my ($msg, $files) = @_;

    foreach my $temp_fh (@$files)
    {
	print $temp_fh ($msg);
    }
}

sub _can_write
{
    my ($files, $leave_zero) = @_;
    my %fh_hash = ();
    my ($temp_fh, $name);

    foreach (keys %$files)
    {
	
	if (not ref ($files->{$_}))
	{
	    $temp_fh = FileHandle::new FileHandle;
	    
	    unless (open ($temp_fh, "$files->{$_}"))
	    {
		print $LH_ERROR ("unable to open $files->{$_}.\n$!\n");
		carp ("unable to open $files->{$_}.\n$!\n");
		next;
	    }
	    
	    $name = $files->{$_};
	    $name =~ s/^>+//;
	}
	else
	{
	    if (not ref ($leave_zero))
	    {
		undef $leave_zero;
	    }

	    $temp_fh = $files->{$_};
	    $name = "\0\0";   #this shouldn't conflict with a user provided name
	    $leave_zero->{$_} = 1;
	}

	$fh_hash{$_} = {
	                'fh'    => $temp_fh,
			'name'  => $name
		       };
    }

    return \%fh_hash, $leave_zero;
}

__END__

=head1 NAME

Log::Handler - Log Handler object

=head1 SYNOPSIS

  use Log::Handler;

  $lh = new Log::Handler (
        {
         'dave'       => 'grimes@waste.org',
         'matt'       => 'bob@foo.com',
         'sharyn'     => 'sharyn@freak.foo.org'
        },
        {
         'debug'      => '>debug_log.txt',
         'kaboom'     => '>BIG_error_log.txt',
         'minor'      => '>small_error.log',
         'permanent'  => '>>gonna_get_huge.log'
        }
                         );

  open (FOO, "foo.txt") || $lh->lhdie ("unable to open the data file\n$!\n");

  if (-z "foo.txt")
  {
      $lh->log ("foo.txt is 0 bytes long", ['dave', 'sharyn'], ['debug', 'minor'], 'screen');
  }

  $ADMINS = ['matt', 'sharyn'];
  $DEBUG_LOGS = ['debug', 'permanent'];

  unlink ("foo.txt") || $lh->lhwarn ("can't delete the darn thing\n$!\n", $ADMINS, '-all', 1);

  if ($DEBUG)
  {
      $lh->log ("It doesn't have to just be an error message!\n", '', $DEBUG_LOGS);
  }

=head1 DESCRIPTION

The C<Log::Handler> object provides a substitute for warn and die
and is particularly appropriate for scripts that will run unattended
like cron jobs.  It is initialized with two anonymous hashes.  One is
a hash of names (or anything) and email addresses.  The other is a
hash of names (again, or anything) and file names (with mode indicated
by '>' or '>>').  It is possible to have one or the other of these
hashes be empty or undefined, but not both! 

The object has three primary methods, lhdie, lhwarn, and log.  The
default behavior for an C<Log::Handler> object is to send messages to
all the addresses provided and to write to all the files provided,
while sending no output to the screen.  This can changed, as can be
seen by looking at the L<SYNOPSIS> or L<METHODS> sections.

B<NOTE!>: The Log::Handler reserves the file C<lh_int_error.$$> for
internal errors.  It creates it in the same directory as the script is
run from.  If the file is empty it will remove it when the object is
destroyed.  For the true completist, you may want to write a cron job
to check for these files (as they may tell you something useful).  In
any case, you don't want to try to use this file name (well, you may
want to but if you do it'll probably cause problems so please restrain
yourself).  This file is global for each usage of the module.  This means
that if you create multiple Log::Handler objects in one process, they
will all write their errors to the same file.  This should probably change.

=head1 METHODS

B<new>    (EMAIL_RECIPIENTS, FILES[, NO_CLEANUP])

EMAIL_RECIPIENTS must be a reference to a hash of strings to email
addresses.  Something like:

{'evan'=>'lazy@sleepy.com', 'heidi'=>'nanny@foo.org'}

FILES must be a reference to a hash of strings to either file names
(with modes!), or objects that act as file handles (anything can be
used in the context of:

  print $foo "some text";

If you provide an object, you are responsible for opening it, making
sure that it is writable, and closing it.  Log::Handler will not
attempt to do this for you.  In addition, if you provide objects, you
cannot set NO_CLEANUP as false for all file.  There is not much point
in doing this anyway because it's the default behavior.  However, you
can set NO_CLEANUP as true for all files no matter what.

Files should look something like:

{'log' => '>/logs/log.log', 'permanent' => '>>permanent.log',
 'thingy' => $filehandle}

Log::Handler checks to see that each file name can be opened during
object creation.

NO_CLEANUP can be one of two things.

It can be a boolean value.  If true, when the object is destroyed
it will not attempt to delete files that are 0 bytes in size during
DESTROY.  This is useful if you are using a device as a file name.  If
this parameter is not provided then it will be set to 0 and DESTROY
will run as normal.

It can also be a hash of strings to boolean values.  These strings
must be the same as those given as indexes for the filenames.  This
allows you to control the cleanup behavior of Log::Handler on a file
by file basis.

The default for NO_CLEANUP is false.  See the About DESTROY section
for more information on what this means.

You must provide either EMAIL_RECIPIENTS or FILES.  Otherwise object
creation will fail.  In addition, if you provide only FILES and none
can be opened, object creation will fail.

B<lhwarn> (MESSAGE[, EMAIL_RECIPIENTS, FILES, SCREEN])

B<log>    (MESSAGE[, EMAIL_RECIPIENTS, FILES, SCREEN])

B<lhdie>  (MESSAGE[, EMAIL_RECIPIENTS, FILES, SCREEN])

B<log> and B<lhwarn> are the same thing (at least in this version.
This could change in the future).

MESSAGE is a string of any length.

EMAIL_RECIPIENTS can be any of the following:

Undefined.  This will cause the error message to go to all of
the email recipients defined during object creation

A reference to an array containing any number of strings, each
of which must be a name associated with an email address at object
creation.

A string containing the word 'all' (any case) or a number with
the value 1.  This is the same as undefined in that it sends email to
all the recipients defined during object creation.

An empty string ('') or a 0.  No email will be sent for this
particular error message.


FILES can be any of the following:

Undefined.  This will cause the error message to be written to
all of files defined during object creation

A reference to an array containing any number of strings, each
of which must be a name associated with a file at object creation.

A string containing the word 'all' (any case) or a number with
the value 1.  This is the same as undefined in that it writes to all
the files defined during object creation.

An empty string ('') or a 0.  No files will be written to for this
particular message.


SCREEN is a Boolean value.  If true, it writes the message to STDOUT
(which conceivably could have been redirected in the main program and
may not be the screen but that's your problem).

examples:

  $lh->lhwarn ("Uh-oh.\n$!\n");

Sends the warning to all of the email recipients and files defined
at object creation but not to the screen.

  $lh->log ("Something or other happened\n", ['skaht', 'miguel']);

Sends the message (and such a helpful message it is, isn't it?) to the
email addresses associated with 'skaht' and 'miguel'.  Also send the
warning to all of the files defined at object creation but not to the
screen.

  $lh->lhdie  ("Uh-oh.\n$!\n", '', ['debuglog', 'mainlog']);

Writes the error message to the files associated with 'debuglog' and
'mainlog' and does not send any email.  This error will be fatal.

  $GREAT_AUTHORS = ['Gene Wolfe', 'Sean Stewart'];
  $lh->lhdie  ("Uh-oh.\n$!\n", $GREAT_WRITERS, 'ALL', 1);

Send the error message to Gene Wolfe and Sean Stewart (two of my
favorite authors), or at least the email addresses associated with
those names and writes it to all of the files defined at object
creation.  It also sends it to the screen.

B<NOTE>: Sending the message to the screen when using B<lhdie> is
probably redundant since it causes a croak in the Log::Handler
module which should send the error message to STDOUT anyway.  But
whatever.


  $SOME_FILES = ['important', 'personal', 'dev-lp0']
  $lh->lhwarn ("Go vegan for your health, the animals, and the
  earth.\n$!\n, 0, $SOME_FILES, 'screen');

Writes a warning to the files associated with 'important', 'personal',
'dev-lp0', and the screen ('screen' evaluates to true and is perfectly
legal).  It does not send any email.

B<close> (FILES)

FILES must be a reference to an array of strings.
Close the filehandles associated with the list of names provided.

B<open>  (FILES)

FILES must be a reference to an array of strings.
Open the filehandles associated with the list of names provided.
These will be opened in B<append> mode.

Attempting to use B<close> or B<open> with a string that refers to
an object that you provided will just cause an error (non-fatal).


=head1 ADDITIONAL INFO

=head2 How does Log::Handler send mail?


There are several ways in which this module tries to send mail.  The
method is determined when the module is loaded into the script.  They
are tried in the following order.

1. Use the Mail::Send module.

2. Use the Mail::Sendmail module.

3. Look in a number of directories on the local machine for the
sendmail program and use that.  This last method is a gross kludge.
Get one of the two modules above and use that.

=head2 About DESTROY

When DESTROY is called (when the reference count of the object goes to
zero or the B<lhdie> method has been called), it goes through each of
the files it was given and checks to see if they have any data (are
they 0 bytes in size).  If they don't have data they are deleted.
This behavior can be changed when the object is created by setting
NO_CLEANUP to 1 (either for the whole object or on a file by file
basis.  See documentation for B<new>).

=head1 AUTHOR

David Rolsky (grimes@waste.org).  I welcome bug reports, comments,
questions, etc (please read this documentation thoroughly first,
however).

=head1 VERSION

This is version 0.30

I consider it to be an alpha release.  The interface may change
(although not significantly).  I expect to be able to support the
current interface through any possible future changes.

=head1 HISTORY

0.30
fixed bug that cause lh_int_error.$$ to always be deleted (oops!)
added ability to specify cleanup on a per file basis.
added ability to use user provided objects in place of file names.

0.26
removed a debugging statement accidentally left in

0.25
added log method

0.20
added open and close methods, fixed several bugs.  Changed name to Log::Handler

0.10
initial version

=head1 TODO

Make the error log file for Log::Handler specific to an object as opposed
to global for the module (0.35)

Add ability to choose email sending method at object creation
(expected in 0.40)

Add ability to interface with syslog (expected in 0.50 (or thereabouts))

Add ability to intercept carp and croak (could end up being a big mess
so it might not happen) (don't know when this will happen)

Other additions will be based on user feedback

=cut
