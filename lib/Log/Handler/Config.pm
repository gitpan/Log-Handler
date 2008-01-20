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

=head2 Config structure

With this method it's possible to load a configuration for your logger. Note that
a special configuration is needed to load it successfully. For each logger it must
exist a own section. Here a hash example:

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
config styles available.

=head2 A default section

If your configuration contains a C<default> section then this parameters are used
for all other sections. Example:

    <file>
        <default>
            mode = append
        </default>

        <my_first_log>
            filename = file1.log
            maxlevel = info
            minlevel = warn
        </my_first_log>

        <my_second_log>
            filename = file2.log
        </my_second_log>

        <my_third_log>
            filename = file3.log
            maxlevel = debug
            minlevel = debug
            mode     = trunc
        </my_third_log>
    </file>

The option C<mode> is set to C<append> for the log file C<file1.log> and C<file2.log>.
For C<file3.log> it's overwritten and set to C<trunc>.

=head3 filename

The configuration file.

=head3 plugin

With this option you can set the plugin you want to use. There are 3 plugins
available at the moment:

    Config::General
    Config::Properties
    YAML

=head3 section

If your configuration is placed in file where you configure your complete program
you can push your logger configuration into a sub section:

    <logger>
        <file>
            <mylog>
                filename = file.log
                minlevel = 0
                maxlevel = 7
            </mylog>
        </file>
    </logger>

    <Another_Script_Config>
        foo = bar
    </Another_Script_Config>

Now your configuration is placed in the C<logger> section. You can load this section with

    $log->config(
        filename => 'file.conf',
        section  => 'logger',
    );

    # or if you load the configuration yourself

    $log->config(
        config  => $config,
        section => 'logger',
    );

    # or just

    $log->config( config => $config->{logger} );

=head3 config

With this option you can pass a configuration that you loaded already but it must
have the right structure! Take a look to the examples!

=head1 PLUGINS

    Config::General     -  inspired by the well known apache config format
    Config::Properties  -  Java-style property files
    YAML                -  optimized for human readability

=head1 EXAMPLES

=head2 Configuration examples

=head3 Config::General

    <file>
        <my_log_file>
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
        </my_log_file>
    </file>

=head3 YAML

    ---
    file:
      my_log_file:
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

    file.my_log_file.reopen = 1
    file.my_log_file.fileopen = 1
    file.my_log_file.maxlevel = info
    file.my_log_file.permissions = 0640
    file.my_log_file.mode = append
    file.my_log_file.timeformat = %b %d %H:%M:%S
    file.my_log_file.trace = 0
    file.my_log_file.debug_mode = 2
    file.my_log_file.minlevel = warn
    file.my_log_file.filename = example.log
    file.my_log_file.newline = 1
    file.my_log_file.prefix = '%T %H[%P] [%L] %S: '

=head2 Load the config from a certain section

The config (Config::General)

    <logger>
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
    </logger>

Load the config

    $log->config(
        filename => 'file.conf',
        section  => 'logger',
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

    <logger>
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
    </logger>

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

    * Log::Handler::Logger::DBI
    * Log::Handler::Logger::Socket

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
our $VERSION = '0.00_03';

use Carp;
use Params::Validate;
use UNIVERSAL::require;
use Log::Handler::Logger;

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
