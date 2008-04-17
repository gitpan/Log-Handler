=head1 NAME

Log::Handler::Output - The output builder class.

=head1 SYNOPSIS

    use Log::Handler::Pattern;

    my $pattern = Log::Handler::Pattern::get_pattern();

=head1 DESCRIPTION

Just for internal usage!

=head1 FUNCTIONS

=head2 get_pattern

=head1 AUTHOR

Jonny Schulz <jschulz.cpan(at)bloonix.de>.

=head1 COPYRIGHT

Copyright (C) 2007 by Jonny Schulz. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

package Log::Handler::Pattern;

use strict;
use warnings;
our $VERSION = '0.00_01';

use POSIX;
use Sys::Hostname;
use Log::Handler::Output;

my $progname = $0;
$progname =~ s@.*[/\\]@@;

sub get_pattern {
    return {
        '%L'  => {  name => 'level',
                    code => \&_get_level },
        '%T'  => {  name => 'time',
                    code => \&_get_time },
        '%D'  => {  name => 'date',
                    code => \&_get_date },
        '%P'  => {  name => 'pid',
                    code => \&_get_pid },
        '%H'  => {  name => 'hostname',
                    code => \&Sys::Hostname::hostname },
        '%N'  => {  name => 'newline',
                    code => "\n" },
        '%C'  => {  name => 'caller',
                    code => \&_get_Caller },
        '%c'  => {  name => 'caller',
                    code => \&_get_caller },
        '%p'  => {  name => 'progname',
                    code => $progname },
        '%t'  => {  name => 'mtime',
                    code => \&_get_hires },
        '%m'  => {  name => 'message',
                    code => \&_get_message },
    }
}

sub _get_level   { $Log::Handler::Output::LEVEL }
sub _get_time    { POSIX::strftime($Log::Handler::Output::OBJECT->{timeformat}, localtime) }
sub _get_date    { POSIX::strftime($Log::Handler::Output::OBJECT->{dateformat}, localtime) }
sub _get_pid     { $$ }
sub _get_Caller  { my @c = caller($Log::Handler::Output::CALLER); "$c[1], line $c[2]" }
sub _get_caller  { my @c = caller($Log::Handler::Output::CALLER); "$c[0], $c[1] line $c[2]" }
sub _get_message { $Log::Handler::Output::MESSAGE }
sub _get_hires   { Log::Handler::Output::_measurement($Log::Handler::Output::OBJECT) }

1;
