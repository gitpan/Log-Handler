#!/usr/bin/perl

=head1 AUTHOR

Jonny Schulz <jschulz.cpan(at)bloonix.de>

=head1 DESCRIPTION

This script shows you different configuration styles.

You can change or add examples to see how the configuration
looks like.

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
use YAML;
use Config::General;
use Config::Properties;

my %config;

$config{example1} = {
    file => {
        filename => 'example.log',
        maxlevel => 'info',
        minlevel => 'warn',
    },
    screen => {
        maxlevel => 'warn',
        minlevel => 'emergency',
    },
};

$config{example2} = {
    file => [
        {
            alias    => 'common',
            filename => 'example.log',
            maxlevel => 'info',
            minlevel => 'warn',
        },
        {
            alias    => 'error',
            filename => 'example-error.log',
            maxlevel => 'warn',
            minlevel => 'emergency',
        },
        {
            alias    => 'debug',
            filename => 'example-debug.log',
            maxlevel => 'debug',
            minlevel => 'debug',
        }
    ],
    screen => {
        maxlevel => 'warn',
        minlevel => 'emergency',
    },
};

$config{example3} = {
    file => {
        default => {
            newline     => 1,
            permissions => '0664',
        },
        common => {
            filename => 'example.log',
            maxlevel => 'info',
            minlevel => 'warn',
        },
        error => {
            filename => 'example-error.log',
            maxlevel => 'warn',
            minlevel => 'emergency',
        },
        debug => {
            filename => 'example-debug.log',
            maxlevel => 'debug',
            minlevel => 'debug',
        }
    }
};

foreach my $x (sort keys %config) {
    print '*' x 20, " YAML $x ", '*' x 20, "\n\n";
    print YAML::Dump($config{$x}), "\n";

    print '*' x 20, " Config::Properties $x ", '*' x 20, "\n\n";
    my $props = Config::Properties->new();
    $props->setFromTree($config{$x}, '.');
    print $props->saveToString($x, $config{$x}), "\n";

    print '*' x 20, " Config::General $x ", '*' x 20, "\n\n";
    my $conf = Config::General->new();
    print $conf->save_string($config{$x}), "\n";
}
