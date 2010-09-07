=head1 NAME

Log::Handler::Levels - All levels for Log::Handler.

=head1 DESCRIPTION

Base class for Log::Handler.

Just for internal usage and documentation.

=head1 METHODS

=head2 Default log level

=over

=item B<debug()>

=item B<info()>

=item B<notice()>

=item B<warning()>, B<warn()>

=item B<error()>, B<err()>

=item B<critical()>, B<crit()>

=item B<alert()>

=item B<emergency()>, B<emerg()>

=back

=head2 Checking for active levels

=over

=item B<is_debug()>

=item B<is_info()>

=item B<is_notice()>

=item B<is_warning()>, B<is_warn()>

=item B<is_error()>, B<is_err()>

=item B<is_critical()>, B<is_crit()>

=item B<is_alert()>

=item B<is_emergency()>, B<is_emerg()>

=back

=head2 Special level

=over

=item B<fatal()>

Alternative for the levels C<critical> - C<emergency>.

=item B<is_fatal()>

Check if one of the levels C<critical> - C<emergency> is active.

=back

=head2 Special methods

=over

=item B<trace()>

This method is very useful if you want to add a full backtrace to
your message. Maybe you want to intercept unexpected errors and
want to know who called C<die()>.

    $SIG{__DIE__} = sub { $log->trace(emergency => @_) };

=item B<dump()>

If you want to dump something then you can use C<dump()>.
The default level is C<debug>.

    my %hash = (foo => 1, bar => 2);

    $log->dump($level => \%hash);

=item B<die()>

This method logs the message to the output and then call C<Carp::croak()>
with the level C<emergency> by default.

    $log->die(fatal => 'an emergency error here');

=item B<log()>

With this method it's possible to log messages with the log level as
first argument:

    $log->log(info => 'an info message');

=item B<tagged()>

With this method it's possible to add some tags to a message:

    $log->tagged(
        level    => "debug",
        message  => "log this message",
        karma    => 42,
        tags     => "security,foo",
    );

=back

=head1 PREREQUISITES

    Carp
    Data::Dumper

=head1 EXPORTS

No exports.

=head1 REPORT BUGS

Please report all bugs to <jschulz.cpan(at)bloonix.de>.

If you send me a mail then add Log::Handler into the subject.

=head1 AUTHOR

Jonny Schulz <jschulz.cpan(at)bloonix.de>.

=head1 COPYRIGHT

Copyright (C) 2007-2010 by Jonny Schulz. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

package Log::Handler::Levels;

use strict;
use warnings;
use Carp;
use Data::Dumper;

our $VERSION = '0.07';

my %LEVELS_BY_ROUTINE = (
    debug     => 'DEBUG',
    info      => 'INFO',
    notice    => 'NOTICE',
    warning   => 'WARNING',
    warn      => 'WARNING',
    error     => 'ERROR',
    err       => 'ERROR',
    critical  => 'CRITICAL',
    crit      => 'CRITICAL',
    alert     => 'ALERT',
    emergency => 'EMERGENCY',
    emerg     => 'EMERGENCY',
    fatal     => 'FATAL',
);

foreach my $routine (keys %LEVELS_BY_ROUTINE) {
    my $level = $LEVELS_BY_ROUTINE{$routine};

    {   # start "no strict 'refs'" block
        no strict 'refs';

        # --------------------------------------------------------------
        # Creating the syslog level methods
        # --------------------------------------------------------------

        *{"$routine"} = sub {
            use strict 'refs';
            my $self   = shift;
            my $levels = $self->{levels};
            my $errors = ();

            if ( !$levels->{$level} ) {
                return 1;
            }

            foreach my $output ( @{$levels->{$level}} ) {
                if ( !$output->log($level, @_) ) {
                    if ( defined $errors ) {
                        $errors .= '; ' . $output->errstr;
                    } else {
                        $errors = $output->errstr;
                    }
                }
            }

            return defined $errors ? $self->_raise_error($errors) : 1;
        };

        # --------------------------------------------------------------
        # Creating the is_<level> methods
        # --------------------------------------------------------------

        *{"is_$routine"} = sub {
            use strict 'refs';
            my $self = shift;
            my $levels = $self->{levels};
            return $levels->{$level} ? 1 : 0;
        };

    } # end "no strict 'refs'" block
}

sub tagged {
    my $self  = shift;
    my $tags  = ref($_[0]) eq "HASH" ? shift : {@_};
    my $level = $tags->{level};

    if (!defined $level) {
        $level = $tags->{level} = "info";
    }

    if (!exists $LEVELS_BY_ROUTINE{$level}) {
        $level = $tags->{level} = "info";
    }

    local $Log::Handler::CALLER_LEVEL = 1;
    return $self->$level($tags);
}

sub log {
    my $self  = shift;
    my $level = @_ > 1 ? lc(shift) : 'info';
    if (!exists $LEVELS_BY_ROUTINE{$level}) {
        $level = 'info';
    }
    local $Log::Handler::CALLER_LEVEL = 1;
    return $self->$level(@_);
}

sub trace {
    my $self  = shift;
    my $level = @_ > 1 ? lc(shift) : 'debug';
    if (!exists $LEVELS_BY_ROUTINE{$level}) {
        $level = 'debug';
    }
    local $Log::Handler::CALLER_LEVEL = 1;
    local $Log::Handler::TRACE = 1;
    return $self->$level(@_);
}

sub die {
    my $self  = shift;
    my $level = @_ > 1 ? lc(shift) : 'emergency';
    if (!exists $LEVELS_BY_ROUTINE{$level}) {
        $level = 'emergency';
    }
    local $Log::Handler::CALLER_LEVEL = 1;
    my @caller = caller;
    $self->$level(@_, "at line $caller[2]");
    Carp::croak @_;
};

sub dump {
    my $self  = shift;
    my $level = @_ > 1 ? lc(shift) : 'debug';
    if (!exists $LEVELS_BY_ROUTINE{$level}) {
        $level = 'debug';
    }
    local $Log::Handler::CALLER_LEVEL = 1;
    return $self->$level(Dumper(@_));
}

1;
