=head1 NAME

Log::Handler::Config - The main config loader.

=head1 SYNOPSIS

    use Log::Handler;

    my $log = Log::Handler->new();

    # Config::General
    $log->config(config => 'file.conf');

    # Config::Properties
    $log->config(config => 'file.props');

    # YAML
    $log->config(config => 'file.yaml');

Or

    use Log::Handler;

    my $log = Log::Handler->new();

    $log->config(
        config => 'file.conf'
        plugin => 'YAML',
    );

=head1 DESCRIPTION

This module makes it possible to load the configuration from a file.
The configuration type is determined by the file extension. It's also
possible to mix file extensions with another configuration types.

=head1 PLUGINS

    Plugin name             File extensions
    ------------------------------------------
    Config::General         cfg, conf 
    Config::Properties      props, jcfg, jconf
    YAML                    yml, yaml

If the extension is not defined then C<Config::General> is used by default.

=head1 METHODS

=head2 config()

With this method it's possible to load the configuration for your outputs.

The following options are valid:

=over 4

=item B<config>

With this option you can pass a file name or the configuration as a
hash reference.

    $log->config(config => 'file.conf');
    # or
    $log->config(config => \%config);

=item B<plugin>

With this option it's possible to say which plugin you want to use.
Maybe you want to use the file extension C<conf> with C<YAML>, which
is reserved for the plugin C<Config::General>.

Examples:

    # this would use Config::General
    $log->config(
        config => 'file.conf'
    );

    # this would force .conf with YAML
    $log->config(
        config => 'file.conf',
        plugin => 'YAML'
    );

=item B<section>

If you want to write the configuration into a global configuration file
then you can create a own section for the logger:

    <logger>
        <file>
            <mylog>
                filename = file.log
                minlevel = 0
                maxlevel = 7
            </mylog>
        </file>
    </logger>

    <another_script_config>
        foo = bar
        bar = baz
        baz = foo
    </another_script_config>

Now your configuration is placed in the C<logger> section. You can load this
section with

    $log->config(
        config  => 'file.conf',
        section => 'logger',
    );

    # or if you load the configuration yourself to %config

    $log->config(
        config  => \%config,
        section => 'logger',
    );

    # or just

    $log->config( config => $config{logger} );

Note that the section C<mylog> is used as an C<alias>. Later you access the
output with

    my $file_output = $log->output('mylog');

    $file_output->log(message => 'your message');

=back

=head1 PLUGINS

    Config::General     -  inspired by the well known apache config format
    Config::Properties  -  Java-style property files
    YAML                -  optimized for human readability

=head1 EXAMPLES

=head2 Config structure

For each output it must exist an own section. Here a example as hash:

    my %config = (

        # the configuration for a file

        file => {
            foo => {
                filename => 'file1.log',
                maxlevel => 'info',
                minlevel => 'warn',
            },
            bar => {
                filename => 'file2.log',
                maxlevel => 'error',
                minlevel => 'emergency',
            }
        }

        # the configuration for email

        email => {
            baz =>
                host     => 'foo.example',
                from     => 'me@me.example',
                to       => 'you@foo.example',
                maxlevel => 'error',
                minlevel => 'emergency',
            },

            # and_so_on ...
        }
    );

You can store your configuration to a file and loads it. There are different
config plugins available.

=head2 A default section

It's possible to define a section called C<default> for each output. This
options are used as default if this options are not set. Example:

    my %config = (
        # the configuration for a file
        file => {
            default => {
                mode     => 'append',
            },
            foo => {
                filename => 'file1.log',
                maxlevel => 'info',
                minlevel => 'warn',
            },
            bar => {
                filename => 'file2.log',
                maxlevel => 'error',
                minlevel => 'emergency',
            },
            baz => {
                filename => 'file3.log',
                maxlevel => 'debug',
                minlevel => 'debug',
                mode     => 'trunc',
            },
        },
        # the configuration for dbi
        dbi => {
            default => { ... }
        }
    );

The option C<mode> is set to C<append> for the log file C<file1.log> and
C<file2.log>. The configuration for C<file3.log> will be set to C<trunc>.

=head2 Examples for the config plugins

=head3 Config::General

    <file>
        <mylog>
            fileopen = 1
            reopen = 1
            permissions = 0640
            maxlevel = info
            minlevel = warn
            mode = append
            timeformat = %b %d %H:%M:%S
            debug_mode = 2
            filename = example.log
            message_layout = '%T %H[%P] [%L] %S: %m'
            newline = 1
        </mylog>
    </file>

=head3 YAML

    ---
    file:
      mylog:
        debug_mode: 2
        filename: example.log
        fileopen: 1
        maxlevel: info
        minlevel: warn
        mode: append
        newline: 1
        permissions: 0640
        message_layout: '%T %H[%P] [%L] %S: %m'
        reopen: 1
        timeformat: '%b %d %H:%M:%S'

=head3 Config::Properties

    file.mylog.reopen = 1
    file.mylog.fileopen = 1
    file.mylog.maxlevel = info
    file.mylog.minlevel = warn
    file.mylog.permissions = 0640
    file.mylog.mode = append
    file.mylog.timeformat = %b %d %H:%M:%S
    file.mylog.debug_mode = 2
    file.mylog.filename = example.log
    file.mylog.newline = 1
    file.mylog.message_layout = '%T %H[%P] [%L] %S: %m'

=head2 Load the config from a certain section

The config (Config::General)

    <output>
        <file>
            <default>
                newline        = 1
                permissions    = 0640
                timeformat     = %b %d %H:%M:%S
                fileopen       = 1
                reopen         = 1
                mode           = append
                message_layout = "%T %H[%P] [%L] %S: %m"
                debug_mode     = 2
            </default>

            <common>
                filename = example.log
                maxlevel = info
                minlevel = warn
            </common>

            <error>
                filename = example-error.log
                maxlevel = warn
                minlevel = emergency
            </error>

            <debug>
                filename = example-debug.log
                maxlevel = debug
                minlevel = debug
            </debug>
        </file>
    </output>

Load the config

    $log->config(
        config  => 'file.conf',
        section => 'output',
    );

=head2 Simple configuration without a certain section

The config (Config::General)

    <file>
        <default>
            newline        = 1
            permissions    = 0640
            timeformat     = %b %d %H:%M:%S
            fileopen       = 1
            reopen         = 1
            mode           = append
            message_layout = "%T %H[%P] [%L] %S: $m"
            debug_mode     = 2
        </default>

        <common>
            filename = example.log
            maxlevel = info
            minlevel = warn
        </common>

        <error>
            filename = example-error.log
            maxlevel = warn
            minlevel = emergency
        </error>

        <debug>
            filename = example-debug.log
            maxlevel = debug
            minlevel = debug
        </debug>
    </file>

Load the config

    $log->config(config => 'file.conf');

=head2 The config as hash

    $log->config(
        config => {
            file => {
                default => {
                    newline        => 1,
                    permissions    => '0640',
                    timeformat     => '%b %d %H:%M:%S',
                    fileopen       => 1,
                    reopen         => 1,
                    mode           => 'append',
                    message_layout => '%T %H[%P] [%L] %S: %m',
                    debug_mode     => 2,
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
        }
    );

=head2 Configuration for different outputs

    <output>
        <file>
            <default>
                newline        = 1
                permissions    = 0640
                timeformat     = %b %d %H:%M:%S
                fileopen       = 1
                reopen         = 1
                mode           = append
                message_layout = "%T %H[%P] [%L] %S: %m"
                debug_mode     = 2
            </default>

            <common>
                filename = example.log
                maxlevel = info
                minlevel = warn
            </common>

            <error>
                filename = example-error.log
                maxlevel = warn
                minlevel = emergency
            </error>
        </file>
    </output>

=head1 PREREQUISITES

    Carp
    Params::Validate
    UNIVERSAL::require

=head1 EXPORTS

No exports.

=head1 REPORT BUGS

Please report all bugs to <jschulz.cpan(at)bloonix.de>.

If you send me a mail then add Log::Handler into the subject.

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
our $VERSION = '0.03';

use Carp;
use File::Spec;
use Params::Validate;
use UNIVERSAL::require;

sub config {
    my $class  = shift;
    my $params = $class->_validate(@_);
    my $plugin = $params->{plugin};
    my ($config, %all_configs);

    if (ref($params->{config})) {
        $config = $params->{config};
    } elsif ($params->{config}) {
        $plugin->require or Carp::croak "unable to load plugin '$plugin'";
        $config = $plugin->get_config($params->{config});
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
            %default = (%{ $type_config->{default} });
        }

        # Structure:
        #   $all_configs{file} = [ \%a, \%b, \%c ]
        #   $all_configs{dbi}  = [ \%a, \%b, \%c ]

        while ( my ($name, $log_config) = each %$type_config ) {
            $class->_is_hash($name, $log_config);
            next if $name eq 'default';
            my %new_config = (%default, %$log_config, alias => $name);
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
        config => {
            type => Params::Validate::SCALAR
                  | Params::Validate::HASHREF
                  | Params::Validate::ARRAYREF,
        },
        plugin => {
            type => Params::Validate::SCALAR,
            optional => 1,
        },
        section => {
            type => Params::Validate::SCALAR,
            optional => 1,
        },
    });

    if (ref($options{config}) eq 'ARRAY') {
        $options{config} = File::Spec->catfile(@{$options{config}});
    }

    if (!$options{plugin}) {
        if (!ref($options{config})) {
            if ($options{config} =~ /\.ya{0,1}ml\z/) {
                $options{plugin} = 'Log::Handler::Plugin::YAML';
            } elsif ($options{config} =~ /\.(?:props|jc(?:onf|fg))\z/) {
                $options{plugin} = 'Log::Handler::Plugin::Config::Properties';
            } else {
                $options{plugin} = 'Log::Handler::Plugin::Config::General';
            }
        }
    }

    return \%options;
}

sub _is_hash {
    my ($self, $name, $ref) = @_;
    if (ref($ref) ne 'HASH') {
        Carp::croak "bad config structure! Config name '$name' missplaced";
    }
}

1;
