=head1 NAME

Log::Handler::Config - A simple config loader.

=head1 SYNOPSIS

    my $log = Log::Handler->new;

    $log->config(filename => 'file.conf');

=head1 DESCRIPTION

This module makes it possible to load the configuration for the Log::Handler.

=head1 METHODS

=head2 config()

With this method it's possible to load a configuration for your logger.

If your configuration contains a C<default> section then this parameters
are used for all other log files. Example:

    <default>
        mode = append
    </default>

    <file1>
        filename = file1.log
    </file2>

    <file2>
        filename = file2.log
    </file2>

    <file3>
        filename = file3.log
        mode     = trunc
    </file3>

The option C<mode> is set for C<file1.log> and C<file2.log> to C<append>,
for C<file3.log> it's set to C<trunc>.

=head3 filename

The configuration file.

=head3 plugin

The plugin you want to use to load the configuration file. There are 3 plugins
available:

    Config::General
    Config::Properties
    YAML

=head3 section

Load the logger configuration from a main section. Example:

    <Log::Handler>
        <log_all>
            filename = file.log
            minlevel = 0
            maxlevel = 7
        </mylog>
    </Log::Handler>

    <Another_Script_Config>
        foo = bar
    </Another_Script_Config>

Now you just want to load the the section C<Log::Handler>. You can do this with

    $log->config(
        filename => 'file.conf',
        section  => 'logger',
    );

    # or if you got the configuration already

    $log->config(
        config  => $config,
        section => 'logger',
    );

=head3 config

With this option you can pass a configuration that you got already.

=head1 PLUGINS

=head2 Config::General

    Config::General     -  inspired by the well known apache config format
    Config::Properties  -  Java-style property files
    YAML                -  optimized for human readability

=head1 EXAMPLES

=head2 Load from a section

The config (Config::General)

    <logger>
        <default>
            newline     = 1
            permissions = 0640
            timeformat  = %b %d %H:%M:%S
            fileopen    = 1
            reopen      = 1
            mode        = append
            prefix      = "%T %H[%P] [%L] %S: "
            trace       = 0
            debug_mode  = 2
        </default>

        <common>
            filename    = example.log
            maxlevel    = info
            minlevel    = warn
        </common>

        <error>
            filename    = example-error.log
            maxlevel    = warn
            minlevel    = emergency
            trace       = 1
        </error>

        <debug>
            filename    = example-debug.log
            maxlevel    = debug
            minlevel    = debug
        </debug>
    </logger>

Load the config

    $log->config(
        filename => 'file.conf',
        section  => 'Log::Handler',
        plugin   => 'Config::General',
    );

=head2 Simple configuration without a main section

The config (Config::General)

    <default>
        newline     = 1
        permissions = 0640
        timeformat  = %b %d %H:%M:%S
        fileopen    = 1
        reopen      = 1
        mode        = append
        prefix      = "%T %H[%P] [%L] %S: "
        trace       = 0
        debug_mode  = 2
    </default>

    <common>
        filename    = example.log
        maxlevel    = info
        minlevel    = warn
    </common>

    <error>
        filename    = example-error.log
        maxlevel    = warn
        minlevel    = emergency
        trace       = 1
    </error>

    <debug>
        filename    = example-debug.log
        maxlevel    = debug
        minlevel    = debug
    </debug>

Load the config

    $log->config(
        filename => 'file.conf',
        section  => 'Log::Handler',
        plugin   => 'Config::General',
    );

=head2 The config as hash

    $log->config(
        config => {
            default => {
                newline     => 1,
                permissions => '0640',
                timeformat  => '%b %d %H:%M:%S',
                fileopen    => 1,
                reopen      => 1,
                mode        => 'append
                prefix      => '%T %H[%P] [%L] %S: ',
                trace       => 0,
                debug_mode  => 2,
            },
            common => {
                filename    => 'example.log',
                maxlevel    => 'info',
                minlevel    => 'warn',
            },
            error => {
                filename    => 'example-error.log',
                maxlevel    => 'warn',
                minlevel    => 'emergency',
                trace       => 1,
            },
            debug => {
                filename    => 'example-debug.log',
                maxlevel    => 'debug',
                minlevel    => 'debug',
            },
        }
    );

=head1 PREREQUISITES

    Carp
    Params::Validate
    UNIVERSAL::require

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

package Log::Handler::Config;

use strict;
use warnings;
our $VERSION = '0.00_02';

use Carp;
use Params::Validate;
use UNIVERSAL::require;
use Log::Handler::Logger;

sub config {
    my $class   = shift;
    my $params  = $class->_validate(@_);
    my $plugin  = $params->{plugin};
    my ($config, %all_configs);

    if ($params->{filename}) {
        $plugin->require or Carp::croak "unable to load plugin '$plugin'";
        $config = $plugin->get_config($params->{filename});
    } elsif ($params->{config}) {
        $config = $params->{config};
    } else {
        Carp::croak "missing mandatory option 'filename' or 'config'";
    }

    $class->_is_hash('main', $config);

    if ($params->{section}) {
        $class->_is_hash($params->{section}, $config->{ $params->{section} });
        $config = $config->{ $params->{section} };
    }

    while ( my ($type, $type_config) = each %$config ) {
        $class->_is_hash($type, $type_config);
        my %default = ();

        if ($type_config->{default}) {
            $class->_is_hash('default', $type_config->{default});
            %default = %{ $type_config->{default} };
        }

        while ( my ($name, $log_config) = each %$type_config ) {
            $class->_is_hash($name, $log_config);
            next if $name eq 'default';
            my %new_config = (%default, %$log_config);
            push @{$all_configs{$type}}, \%new_config;
        }
    }

    return \%all_configs;
}

#
# private stuff
#

sub _validate {
    my $class = shift;

    my %options = Params::Validate::validate(@_, {
        filename => {
            type => Params::Validate::SCALAR,
            default => '',
        },
        config => {
            type => Params::Validate::HASHREF,
            default => '',
        },
        plugin => {
            type => Params::Validate::SCALAR,
            regex => qr/./,
            default => 'Config::General',
        },
        section => {
            type => Params::Validate::SCALAR,
            default => '',
        },
    });

    $options{plugin} = "Log::Handler::Plugin::$options{plugin}";

    return \%options;
}

sub _is_hash {
    my ($self, $name, $ref) = @_;
    if (ref($ref) ne 'HASH') {
        Carp::croak "bad config structure! Config name '$name' missplaced";
    }
}

1;
