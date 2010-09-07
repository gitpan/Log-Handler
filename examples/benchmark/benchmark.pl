#!/usr/bin/perl

=head1 AUTHOR

Jonny Schulz <jschulz.cpan(at)bloonix.de>

=head1 DESCRIPTION

Benchmarks... what else could I say...

=head1 POWERED BY

     _    __ _____ _____ __  __ __ __   __
    | |__|  |     |     |  \|  |__|\  \/  /
    |  . |  |  |  |  |  |      |  | >    <
    |____|__|_____|_____|__|\__|__|/__/\__\

=head1 COPYRIGHT

Copyright (C) 2007-2010 by Jonny Schulz. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

use strict;
use warnings;
use Log::Handler;
use Benchmark;

my $BUFFER;
sub buffer {
    $BUFFER .= shift->{message};
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
        alias      => 'message pattern',
        maxlevel   => 'error',
        minlevel   => 'error',
        newline    => 1,
        forward_to => \&buffer,
        message_layout  => '%m',
        message_pattern => [qw/%T %L %P/],
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
my $message = 'foo bar baz';

run("simple pattern output took",    $count, sub { $log->notice($message)  } );
run("default pattern output took",   $count, sub { $log->warning($message) } );
run("complex pattern output took",   $count, sub { $log->info($message)    } );
run("message pattern output took",   $count, sub { $log->error($message)   } );
run("suppressed output took",        $count, sub { $log->debug($message)   } );
run("filtered caller output took",   $count, \&Foo::Bar::emerg               );
run("suppressed caller output took", $count, \&Foo::Baz::emerg               );
run("filtered messages output took", $count, sub { $log->alert($message)   } );

sub run {
    my ($desc, $count, $bench) = @_;
    my $time = timeit($count, $bench);
    print sprintf('%-30s', $desc), ' : ', timestr($time), "\n";
    undef $BUFFER;
}

# Filter messages by caller
package Foo::Bar;
sub emerg { $log->emerg($message) }

# Suppressed messages by caller
package Foo::Baz;
sub emerg { $log->emerg($message) }

1;
