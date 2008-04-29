=head1 NAME

Log::Handler::Plugin::Config::YAML - Config loader for YAML.

=head1 SYNOPSIS

    use Log::Handler::Plugin::Config::YAML;

    my $config = Log::Handler::Plugin::Config::YAML->get_config( $config_file );

=head1 ROUTINES

=head2 get_config()

Expect the config file name and returns the config as a reference.

=head1 CONFIG STYLE

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

=head1 PREREQUISITES
    
    YAML

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

package Log::Handler::Plugin::Config::YAML;

use strict;
use warnings;
use YAML;

our $VERSION = '0.00_06';

sub get_config {
    my ($class, $config_file) = @_;
    my $config = YAML::LoadFile($config_file);
    return $config;
}

1;
