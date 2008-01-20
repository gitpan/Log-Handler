=head1 NAME

Log::Handler::Logger::File - Log messages to a file.

=head1 SYNOPSIS

    use Log::Handler::Logger::File;

    my $log = Log::Handler::Logger::File->new(
        filename    => 'file.log',
        filelock    => 1,
        fileopen    => 1,
        reopen      => 1,
        mode        => 'append',
        autoflush   => 1,
        permissions => '0664',
        utf8        => 0,
    );

    $log->write($message);

=head1 DESCRIPTION

Log messages to a file.

=head1 METHODS

=head2 new()

Call C<new()> to create a new Log::Handler::Logger::File object.

The C<new()> method expected the options for the log file. Each option will
be set to a default value if not set. If this method is called with no options
then it creates an object to log to STDOUT with all default values.

=head2 write()

Call C<write()> if you want to log messages to the log file.

Example:

    $log->write('this message goes to the logfile');

=head2 errstr()

This function returns the last error message.

=head1 OPTIONS

=head2 filename

With C<filename> you can set a file name, a GLOBREF or you can set a string as an alias
for STDOUT or STDERR. The default is STDOUT for this option.

Set a file name:

    my $log = Log::Handler::Logger::File->new( filename => 'file.log'  );

Set a GLOBREF

    open FH, '>', 'file.log' or die $!;
    my $log = Log::Handler::Logger::File->new( filename => \*FH );

Or the same with

    open my $fh, '>', 'file.log' or die $!;
    my $log = Log::Handler::Logger::File->new( filename => $fh );

Set STDOUT or STDERR

    my $log = Log::Handler::Logger::File->new( filename => \*STDOUT );
    # or
    my $log = Log::Handler::Logger::File->new( filename => \*STDERR );

If the option C<filename> is set in a config file and you want to debug to your screen then
you can set C<*STDOUT> or C<*STDERR> as a string.

    my $log = Log::Handler::Logger::File->new( filename => '*STDOUT' );
    # or
    my $log = Log::Handler::Logger::File->new( filename => '*STDERR' );

That is not possible:

    my $log = Log::Handler::Logger::File->new( filename => '*FH' );

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

    my $log = Log::Handler::Logger::File->new(
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

=head2 utf8

If this option is set to 1 then UTF-8 will be set with C<binmode()> on the output filehandle.

=head1 PREREQUISITES

    Fcntl
    Params::Validate

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

package Log::Handler::Logger::File;

use strict;
use warnings;
our $VERSION = '0.00_02';
our $ERRSTR  = '';

use Fcntl qw( :flock O_WRONLY O_APPEND O_TRUNC O_EXCL O_CREAT );
use Params::Validate;

sub new {
    my $class = shift;
    my $self  = $class->_new_file(@_);

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
    my $self    = shift;
    my $message = ();

    if (ref($_[0]) eq 'HASH') {
        $message = $_[0]->{message};
    } else {
        $message = shift;
    }

    if (!$self->{fileopen}) {
        $self->_open or return undef;
    } elsif ($self->{reopen}) {
        $self->_checkino or return undef;
    }

    if ($self->{filelock}) {
        $self->_lock or return undef;
    }

    print {$self->{fh}} $message or
        return $self->_raise_error("unable to print to logfile: $!");

    if ($self->{filelock}) {
        $self->_unlock or return undef;
    }

    if (!$self->{fileopen}) {
        $self->_close or return undef;
    }

    return 1;
}

sub errstr { $ERRSTR }

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

sub _new_file {
    my $class   = shift;
    my $bool_rx = qr/^[10]\z/;

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
        utf8 => {
            type => Params::Validate::SCALAR,
            regex => $bool_rx,
            default => 0,
        },
    });

    return bless \%options, $class;
}

sub _raise_error {
    my $self = shift;
    $ERRSTR = shift;
    return undef;
}

1;