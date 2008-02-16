=head1 NAME

Log::Handler::Levels - All levels for Log::Handler.

=head1 DESCRIPTION

=head1 METHODS

=head2 Log level methods

=over

=item B<debug()>

=item B<info()>

=item B<notice()>

=item B<warning()>

=item B<error()>

=item B<err()>

=item B<critical()>

=item B<crit()>

=item B<alert()>

=item B<emergency()>

=item B<emerg()>

=back

=head2 Checking for active levels

=over

=item B<is_debug()>

=item B<is_info()>

=item B<is_notice()>

=item B<is_warning()>

=item B<is_error()>

=item B<is_err()>

=item B<is_critical()>

=item B<is_crit()>

=item B<is_alert()>

=item B<is_emergency()>

=item B<is_emerg()>

=back

=head2 Special level

=over

=item B<fatal()>

Alternative for the levels C<critical> - C<emergency>.

=item B<is_fatal()>

Check if one of the levels C<critical> - C<emergency> is active.

=back

=head2 Log and trace

These methods are useful if you want to add a full backtrace to your message.

Maybe you like do something like

    $SIG{__DIE__} = sub { $log->fatal_and_trace(@_) };

Or just if you want to know who called who

    $log->info_and_trace('who called who');

=over

=item B<debug_and_trace()>

=item B<info_and_trace()>

=item B<notice_and_trace()>

=item B<warning_and_trace()>

=item B<error_and_trace()>

=item B<err_and_trace()>

=item B<critical_and_trace()>

=item B<crit_and_trace()>

=item B<alert_and_trace()>

=item B<emergency_and_trace()>

=item B<emerg_and_trace()>

=item B<fatal_and_trace()>

=back

=head2 Log and exit

The default exit code is 1

    $log->error_and_exit('an error happends')

Pass the exit code yourself

    $log->error_and_exit(9 => 'an error happends')
    $log->info_and_exit(0 => 'program stopped')

Note that if the first argument is a number then this number is used
as exit code.

=over

=item B<debug_and_exit()>

=item B<info_and_exit()>

=item B<notice_and_exit()>

=item B<warning_and_exit()>

=item B<error_and_exit()>

=item B<err_and_exit()>

=item B<critical_and_exit()>

=item B<crit_and_exit()>

=item B<alert_and_exit()>

=item B<emergency_and_exit()>

=item B<emerg_and_exit()>

=item B<fatal_and_exit()>

=back

=head2 Log and die methods

Log the message to the output and execute C<Carp::croak()>.

=over

=item B<error_and_die()>

=item B<err_and_die()>

=item B<critical_and_die()>

=item B<crit_and_die()>

=item B<alert_and_die()>

=item B<emergency_and_die()>

=item B<emerg_and_die()>

=item B<fatal_and_die()>

=back

=head2 Log and croak methods

Log the message to the output and execute C<Carp::croak()> with C<CarpLevel+3>.

=over

=item B<error_and_croak()>

=item B<err_and_croak()>

=item B<critical_and_croak()>

=item B<crit_and_croak()>

=item B<alert_and_croak()>

=item B<emergency_and_croak()>

=item B<emerg_and_croak()>

=item B<fatal_and_croak()>

=back

=head2 Log and warn methods

=over

=item B<carp()>

    Log the message as warning to the output and execute C<Carp::carp> with C<CarpLevel+3>.

=item B<warn()>

    Log the message as warning to the output and execute C<Carp::carp>.

=back

=head1 PREREQUISITES

    Carp

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

=cut

package Log::Handler::Levels;

use strict;
use warnings;
our $VERSION  = '0.00_01';
use Carp qw();

my %LEVELS_BY_ROUTINE = (
    debug     => 'DEBUG',
    info      => 'INFO',
    notice    => 'NOTICE',
    warning   => 'WARNING',
    error     => 'ERROR',
    err       => 'ERROR',
    critical  => 'CRITICAL',
    crit      => 'CRITICAL',
    alert     => 'ALERT',
    emergency => 'EMERGENCY',
    emerg     => 'EMERGENCY',
    fatal     => 'FATAL',
);

while ( my ($routine, $level) = each %LEVELS_BY_ROUTINE ) {
    {   # start "no strict 'refs'" block
        no strict 'refs';

        # --------------------------------------------------------------
        # Creating the syslog level methods
        # --------------------------------------------------------------

        *{"$routine"} = sub {
            use strict 'refs';
            my $self   = shift;
            my $levels = $self->{levels};

            if ( !$levels->{$level} ) {
                return 1;
            }

            foreach my $output ( @{$levels->{$level}} ) {
                $output->log($level, @_)
                    or return $self->_raise_error($output->errstr);
            }

            return 1;
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

        # --------------------------------------------------------------
        # Creating the <level>_and_trace methods
        # --------------------------------------------------------------

        *{"${routine}_and_trace"} = sub {
            my $self = shift;
            local $Log::Handler::Output::TRACE = 1;
            return $self->$routine(@_);
        };

        # --------------------------------------------------------------
        # Creating the <level>_and_exit methods
        # --------------------------------------------------------------

        *{"${routine}_and_exit"} = sub {
            my $self = shift;
            my $exit_code;
            if (@_) {
                $exit_code = $_[0] =~ /^\d+\z/ ? shift : 1;
                $self->{exit_level}(@_);
            }
            exit $exit_code;
        };

        # --------------------------------------------------------------
        # Creating the <level>_and_croak methods
        # --------------------------------------------------------------

        if ($level =~ /^(?:ERROR|CRITICAL|ALERT|EMERGENCY|FATAL)\z/) {
            *{"${routine}_and_croak"} = sub {
                my $self = shift;
                $self->$routine(@_);
                $Carp::CarpLevel += 3;
                Carp::croak @_;
            };
            *{"${routine}_and_die"} = sub {
                my $self = shift;
                $self->$routine(@_);
                Carp::croak @_;
            };
        }

    } # end "no strict 'refs'" block
}

sub warn {
    my $self = shift;
    $self->warning(@_);
    Carp::carp @_;
}

sub carp {
    my $self = shift;
    $self->warning(@_);
    local $Carp::CarpLevel += 3;
}

1;
