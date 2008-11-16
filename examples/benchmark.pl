#!/usr/bin/perl

=head1 AUTHOR

Jonny Schulz <jschulz.cpan(at)bloonix.de>

=head1 DESCRIPTION

Benchmarks... what else could I say...

=head1 POWERED BY

     _    __ ____ ____ __  __ __ __   __
    | |__|  |    |    |  \|  |__|\  \/  /
    |  . |  |  | |  | |      |  | >    <
    |____|__|____|____|__|\__|__|/__/\__\

=head1 COPYRIGHT

Copyright (C) 2007 by Jonny Schulz. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

use strict;
use warnings;
use Log::Handler;
use Benchmark;

my $BUFFER;
sub buffer {
    $BUFFER .= $_[0]->{message};
}

my $log = Log::Handler->new();

$log->add(
    forward => {
        alias      => 'complex',
        maxlevel   => 'info',
        minlevel   => 'info',
        forward_to => \&buffer,
        message_layout => '%T [%L] %H(%P) %m (%C)%N',
    }
);

$log->add(
    forward => {
        alias      => 'simple',
        maxlevel   => 'notice',
        minlevel   => 'notice',
        newline    => 1,
        forward_to => \&buffer,
        message_layout => '%L - %m',
    }
);

$log->add(
    forward => {
        alias      => 'default & suppressed',
        maxlevel   => 'warning',
        minlevel   => 'warning',
        newline    => 1,
        forward_to => \&buffer,
    }
);

$log->add(
    forward => {
        alias      => 'filter caller',
        maxlevel   => 'emerg',
        minlevel   => 'emerg',
        newline    => 1,
        forward_to => \&buffer,
        filter_caller => qr/^Foo::Bar\z/,
    }
);

$log->add(
    forward => {
        alias      => 'filter message',
        maxlevel   => 'alert',
        minlevel   => 'alert',
        newline    => 1,
        forward_to => \&buffer,
        filter_message => qr/bar/,
    }
);

my $count   = 100_000;
my $message = 'foobarbaz';

print "Iterations: $count\n";
run("simple pattern output took",    sub { $log->notice($message)  for 1..$count } );
run("default pattern output took",   sub { $log->warning($message) for 1..$count } );
run("complex pattern output took",   sub { $log->info($message)    for 1..$count } );
run("suppressed output took",        sub { $log->debug($message)   for 1..$count } );
run("filtered caller output took",   sub { &Foo::Bar::emerg        for 1..$count } );
run("suppressed caller output took", sub { &Foo::Baz::emerg        for 1..$count } );
run("filterd messages output took",  sub { $log->alert($message)   for 1..$count } );

sub run {
    my ($desc, $bench) = @_;
    my $time = timeit(1, $bench);
    printf "%-30s : %10s/s\n", $desc, sprintf('%.2f', $count/$time->[1]);
    undef $BUFFER;
}

# Filter messages by caller
package Foo::Bar;
sub emerg { $log->emerg($message) }

# Suppressed messages by caller
package Foo::Baz;
sub emerg { $log->emerg($message) }

1;
