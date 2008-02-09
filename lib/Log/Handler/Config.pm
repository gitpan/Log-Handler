=head1 NAME

Log::Handler::Config - A simple config loader.

=head1 SYNOPSIS

    use Log::Handler;
    use Log::Handler::Config;

    my $conf = Log::Handler::Config->config(
        filename => 'file.conf',
        plugin   => 'YAML',
        section  => 'Log::Handler',
    );

    my $log = Log::Handler->new();

    while ( my ($type, $config) = each %$conf ) {
        $log->add($type => $config);
    }

    # or

    use Log::Handler;

    my $log = Log::Handler->new();

    $log->config(
        filename => 'file.conf',
        plugin   => 'YAML',
        section  => 'Log::Handler',
    );

=head1 DESCRIPTION

This module makes it possible to load the configuration from a file.

=head1 METHODS

=head2 config()

With this method it's possible to load a configuration for your outputs. Note that
a special structure is needed to load the configuration successfully.

=head3 Config structure

For each output object it must exist a own section. Here a example as hash:

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
            foo =>
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

=head3 A default section

If your configuration contains a C<default> section then this parameters are used
for all other sections. Example:

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
        }

The option C<mode> is set to C<append> for the log file C<file1.log> and C<file2.log>.
For C<file3.log> it's overwritten and set to C<trunc>.

=head1 OPTIONS

=head2 filename

The configuration file.

=head2 plugin

With this option you can set the plugin you want to use. There are 3 plugins
available at the moment:

    Config::General
    Config::Properties
    YAML

If the option is not set then the file extension is used to determine the
configuration style:

    Config::General     -   cfg, conf 
    Config::Properties  -   props, jcfg, jconf
    YAML                -   yml, yaml

Examples:

    # use file.conf and YAML

    $log->config(
        filename => 'file.conf',
        plugin   => 'YAML'
    );

    # automatically use YAML

    $log->config(
        filename => 'file.yaml'
    );

    # automatically use Config::General

    $log->config(
        filename => 'file.conf'
    );

If the extension is not defined then C<Config::General> is used by default.

=head2 section

If your configuration is placed in file where you configure your complete program
you can push your output configuration into a sub section:

    <output>
        <file>
            <mylog>
                filename = file.log
                minlevel = 0
                maxlevel = 7
            </mylog>
        </file>
    </output>

    <Another_Script_Config>
        foo = bar
    </Another_Script_Config>

Now your configuration is placed in the C<output> section. You can load this section with

    $log->config(
        filename => 'file.conf',
        section  => 'output',
    );

    # or if you load the configuration yourself

    $log->config(
        config  => $config,
        section => 'output',
    );

    # or just

    $log->config( config => $config->{output} );

=head2 config

With this option you can pass a configuration that you loaded already but it must
have the right structure! Take a look to the examples!

=head1 PLUGINS

    Config::General     -  inspired by the well known apache config format
    Config::Properties  -  Java-style property files
    YAML                -  optimized for human readability

=head1 EXAMPLES

=head2 Examples for the config plugins

=head3 Config::General

    <file>
        <mylog>
            fileopen = 1
            reopen = 1
            permissions = 0640
            maxlevel = info
            mode = append
            timeformat = %b %d %H:%M:%S
            trace = 0
            debug_mode = 2
            filename = example.log
            minlevel = warn
            prefix = '%T %H[%P] [%L] %S: '
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
        prefix: '%T %H[%P] [%L] %S: '
        reopen: 1
        timeformat: '%b %d %H:%M:%S'
        trace: 0

=head3 Config::Properties

    file.mylog.reopen = 1
    file.mylog.fileopen = 1
    file.mylog.maxlevel = info
    file.mylog.permissions = 0640
    file.mylog.mode = append
    file.mylog.timeformat = %b %d %H:%M:%S
    file.mylog.trace = 0
    file.mylog.debug_mode = 2
    file.mylog.minlevel = warn
    file.mylog.filename = example.log
    file.mylog.newline = 1
    file.mylog.prefix = '%T %H[%P] [%L] %S: '

=head2 Load the config from a certain section

The config (Config::General)

    <output>
        <file>
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
        </file>
    </output>

Load the config

    $log->config(
        filename => 'file.conf',
        section  => 'output',
    );

=head2 Simple configuration without a certain section

The config (Config::General)

    <file>
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
    </file>

Load the config

    $log->config( filename => 'file.conf' );

=head2 The config as hash

    $log->config(
        config => {
            file => {
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
        }
    );

=head2 Configuration for different outputs

    <output>
        <file>
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
        </file>

        <email>
            <default>
                timeout     = 60
                debug       = 0
                subject     = My subject
                buffer      = 100
                interval    = 300
                prefix      = "%T %H[%P] [%L] %S: "
                trace       = 0
                debug_mode  = 2
            </default>

            <admin>
                host        = foo.example
                from        = me@me.example
                to          = you@foo.example
                maxlevel    = error
                minlevel    = emergency
                trace       = 1
            </admin>

            <op>
                host        = bar.example
                from        = me@me.example
                to          = you@bar.example
                maxlevel    = warn
                minlevel    = emergency
            </op>
        </email>
    </output>

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

=head1 QUESTIONS

Do you have any questions or ideas?

MAIL: <jschulz.cpan(at)bloonix.de>

If you send me a mail then add Log::Handler into the subject.
    
=head1 TODO

    * Log::Handler::Output::DBI
    * Log::Handler::Output::Socket

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

package Log::Handler::Config;

use strict;
use warnings;
our $VERSION = '0.00_05';

use Carp;
use File::Spec;
use Params::Validate;
use UNIVERSAL::require;

my %LOADED_PLUGINS = ();

sub config {
    my $class   = shift;
    my $params  = $class->_validate(@_);
    my $plugin  = $params->{plugin};
    my ($config, %all_configs);

    if ($params->{filename}) {
        if (!$LOADED_PLUGINS{$plugin}) {
            $plugin->require or Carp::croak "unable to load plugin '$plugin'";
            $LOADED_PLUGINS{$plugin} = 1;
        }
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
            type => Params::Validate::SCALAR | Params::Validate::ARRAYREF,
            default => '',
        },
        config => {
            type => Params::Validate::HASHREF,
            default => '',
        },
        plugin => {
            type => Params::Validate::SCALAR,
            regex => qr/./,
            default => '',
        },
        section => {
            type => Params::Validate::SCALAR,
            default => '',
        },
    });

    if ($options{filename} && ref($options{filename}) eq 'ARRAY') {
        $options{filename} = File::Spec->catfile(@{$options{filename}});
    }

    if ($options{plugin}) {
        $options{plugin} = "Log::Handler::Plugin::$options{plugin}";
        return \%options;
    }

    my ($file_end) = $options{filename} =~ /\.(.+)\z/;

    if (!$file_end) {
        $options{plugin} = 'Log::Handler::Plugin::Config::General';
    } elsif ($file_end =~ /^c(?:onf|fg)\z/) {
        $options{plugin} = 'Log::Handler::Plugin::Config::General';
    } elsif ($file_end =~ /^ya{0,1}ml\z/) {
        $options{plugin} = 'Log::Handler::Plugin::YAML';
    } elsif ($file_end =~ /^(?:props|jc(?:onf|fg))\z/) {
        $options{plugin} = 'Log::Handler::Plugin::Config::Properties';
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
