=head1 NAME

Log::Handler::Output::DBI - Log messages to a database.

=head1 SYNOPSIS

    use Log::Handler::Output::DBI;

    my $log = Log::Handler::Output::DBI->new(
        # database connection
        database   => 'database',
        driver     => 'mysql',
        user       => 'user',
        password   => 'password',
        host       => '127.0.0.1',
        port       => 3306,

        # debugging
        debug      => 1,

        # table, columns and values (as string)
        table      => 'messages',
        columns    => 'level, ctime, cdate, pid, hostname, caller, progname, mtime, message',
        values     => '%level, %time, %date, %pid, %hostname, %caller, %progname, %mtime, %message',

        # table, columns and values (as array reference)
        table      => 'messages',
        columns    => [ qw/level ctime cdate pid hostname caller progname mtime message/ ],
        values     => [ qw/%level %time %date %pid %hostname %caller %progname %mtime %message/ ],

        # table, columns and values (your own statement)
        statement  => 'insert into messages (level,ctime,cdate,pid,hostname,caller,progname,mtime,message) values (?,?,?,?,?,?,?,?,?)',
        values     => [ qw/%level %time %date %pid %hostname %caller %progname %mtime %message/ ],

        # if you like persistent connections and want to re-connect
        persistent => 1,
        reconnect  => 1,
    );

    $db_output->log(\%message);

=head1 DESCRIPTION

With this output you can insert messages to a database table.

=head1 METHODS

=head2 new()

Call C<new()> to create a new Log::Handler::Output::DBI object.

The following options are possible:

=over 4

=item B<database>

Pass the database name.

=item B<driver>

Pass the database driver.

=item B<user>

Pass the database user for the connect.

=item B<password>

Pass the users password.

=item B<host>

Pass the hostname where the database is running.

=item B<port>

Pass the port where the database is listened.

=item B<table> and B<columns>

With this options you can pass the table name for the insert and the columns.
You can pass the columns as string or as array. Example:

    # the table name
    table => 'messages',

    # columns as string
    columns => 'level, ctime, cdate, pid, hostname, caller, progname, mtime, message',

    # columns as array
    columns => [ qw/level ctime cdate pid hostname caller progname mtime message/ ],

The statement would created as follows

    insert into message (level, ctime, cdate, pid, hostname, caller, progname, mtime, message)
                 values (?,?,?,?,?,?,?,?,?)

=item B<statement>

With this option you can pass your own statement if you don't want to you the options C<table> and C<columns>.

    statement => 'insert into message (level, ctime, cdate, pid, hostname, caller, progname, mtime, message)'
                 .' values (?,?,?,?,?,?,?,?,?)'

=item B<values>

With this option you have to set the values for the insert.

        values => '%level, %time, %date, %pid, %hostname, %caller, %progname, %mtime, %message',

        # or

        values => [ qw/%level %time %date %pid %hostname %caller %progname %mtime %message/ ],

The placeholders are identical with the pattern names that you have to pass with
the option C<message_pattern>.

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

Take a look to the documentation of L<Log::Handler> for all possible patterns.

=item B<persistent> and B<reconnect>

With this option you can enable or disable a persistent database connection and re-connect
if the connection was lost.

If you use persistent connections then a ping is send to the database before each insert.
If the ping fails then a re-connect is executed.

Both options are set to 1 on default.

=item B<dbi_params>

This option is useful if you want to pass arguments to L<DBI>. The default is set to

    {
        PrintError => 0,
        AutoCommit => 1
    }

C<PrintError> is deactivated because this would print error messages as warnings to STDERR.

You can pass your own arguments - and overwrite it - with

    dbi_params => { PrintError => 1, AutoCommit => 0 }

=item B<debug>

With this option it's possible to enable debugging. The informations can be
intercepted with C<$SIG{__WARN__}>.

=back

=head2 log()

=head2 errstr()

This function returns the last error message.

=head1 PREREQUISITES

    Carp
    Params::Validate
    DBI
    your DBI driver you want to use

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

package Log::Handler::Output::DBI;

use strict;
use warnings;
our $VERSION = '0.00_05';
our $ERRSTR  = '';

use Carp;
use DBI;
use Params::Validate;

sub new {
    my $class   = shift;
    my $options = $class->_validate(@_);
    my $self    = bless $options, $class;

    warn "Create a new Log::Handler::Output::DBI object" if $self->{debug};

    if ($self->{persistent}) {
        warn "Peristent connections is set to true" if $self->{debug};
        $self->_connect or return undef;
    }

    return $self;
}

sub log {
    my ($self, $message) = @_;

    #if (!$self->{persistent} || ($self->{dbh} && !$self->{dbh}->ping)) {
    #    $self->_connect or return undef;
    #}

    if ($self->{persistent}) {
        warn "ping the database" if $self->{debug};
        if (!$self->{dbh}->ping) {
            $self->_connect or return undef;
        }
    } else {
        $self->_connect or return undef;
    }

    warn "prepare: $self->{statement}" if $self->{debug};

    my $sth = $self->{dbh}->prepare($self->{statement})
        or return $self->_raise_error("DBI prepare error: ".$self->{dbh}->errstr);

    my @values;

    foreach my $v (@{$self->{values}}) {
        if (ref($v) eq 'CODE') {
            push @values, &$v();
        } elsif ($v =~ /^%(.+)/) {
            push @values, $message->{$1};
        } else {
            push @values, $v;
        }
    }

    warn "execute: ".@values." bind values" if $self->{debug};

    $sth->execute(@values)
        or return $self->_raise_error("DBI execute error: ".$sth->errstr);

    $sth->finish
        or return $self->_raise_error("DBI finish error: ".$sth->errstr);

    if (!$self->{persistent}) {
        $self->_disconnect or return undef;
    }

    return 1;
}

sub errstr { $ERRSTR }

#
# private stuff
#

sub _connect {
    my $self = shift;

    warn "Connect to the database: $self->{cstr}->[0] ..." if $self->{debug};

    my $dbh = DBI->connect(@{$self->{cstr}})
        or return $self->_raise_error("DBI connect error: ".DBI->errstr);

    $self->{dbh} = $dbh;

    return 1;
}

sub _disconnect {
    my $self = shift;
    warn "Disconnect from database" if $self->{debug};
    $self->{dbh}->disconnect
        or return $self->_raise_error("DBI disconnect error: ".DBI->errstr);;
    delete $self->{dbh};
    return 1;
}

sub _validate {
    my $class = shift;

    my %options = Params::Validate::validate(@_, {
        database => {
            type => Params::Validate::SCALAR,
        },
        driver => {
            type => Params::Validate::SCALAR,
        },
        user => {
            type => Params::Validate::SCALAR,
            optional => 1,
        },
        password => {
            type => Params::Validate::SCALAR,
            depends => [ 'user' ],
        },
        host => {
            type => Params::Validate::SCALAR,
            optional => 1,
            depends => [ 'port' ],
        },
        port => {
            type => Params::Validate::SCALAR,
            optional => 1,
        },
        table => {
            type => Params::Validate::SCALAR,
            depends => [ 'columns' ],
            optional => 1,
        },
        columns => {
            type => Params::Validate::SCALAR | Params::Validate::ARRAYREF,
            depends => [ 'table' ],
            optional => 1,
        },
        values => {
            type => Params::Validate::SCALAR | Params::Validate::ARRAYREF,
        },
        statement => {
            type => Params::Validate::SCALAR,
            optional => 1,
        },
        reconnect => {
            type => Params::Validate::SCALAR,
            default => 1,
        },
        persistent => {
            type => Params::Validate::SCALAR,
            default => 1,
        },
        dbi_params => {
            type => Params::Validate::HASHREF,
            default => { PrintError => 0, AutoCommit => 1 },
        },
        debug => {
            type => Params::Validate::SCALAR,
            regex => qr/^[01]\z/,
            default => 0,
        },
    });

    if (!$options{table} && !$options{statement}) {
        Carp::croak "Missing one of the mandatory options: 'statement' or 'table' and 'columns'";
    }

    # build the connect string
    my @cstr = ("dbi:$options{driver}:database=$options{database}");

    if ($options{host}) {
        $cstr[0] .= ";host=$options{host}";
        if ($options{port}) {
            $cstr[0] .= ";port=$options{port}";
        }
    }

    if ($options{user}) {
        $cstr[1] = $options{user};
        if ($options{port}) {
            $cstr[2] = $options{password};
        }
    }

    $cstr[3] = $options{dbi_params};
    $options{cstr} = \@cstr;

    # build the statement

    if (!ref($options{values})) {
        $options{values} = [ split /\s*,\s*/, $options{values} ];
    }

    if (!$options{statement}) {

        $options{statement} = "insert into $options{table} (";

        if (ref($options{columns})) {
            $options{statement} .= join(',', @{$options{columns}});
        } else {
            $options{statement} .= $options{columns};
        }

        $options{statement} .= ') values (';

        my @binds;
        foreach my $v (@{$options{values}}) {
            $v =~ s/^\s+//;
            $v =~ s/\s+\z//;
            push @binds, '?';
        }

        $options{statement} .= join(',', @binds);
        $options{statement} .= ')';
    }

    return \%options;
}

sub _raise_error {
    my $self = shift;
    $ERRSTR = shift;
    return undef;
}

1;
