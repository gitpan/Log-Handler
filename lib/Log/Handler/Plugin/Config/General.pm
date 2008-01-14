=head1 NAME

Log::Handler::Plugin::Config::General - Config loader for YAML.

=head1 SYNOPSIS

    use Log::Handler::Plugin::Config::General;

    my $config = Log::Handler::Plugin::Config::General->get_config( $config_file );

=head1 ROUTINES

=head2 get_config()

Expect the config file name and returns the config as a reference.

=head1 PREREQUISITES
    
    Config::General  -  to load configuration files

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

package Log::Handler::Plugin::Config::General;
our $VERSION = '0.00_01';

use strict;
use warnings;
use Config::General;

sub get_config {
    my ($class, $config_file) = @_;
    my $config = Config::General->new($config_file);
    my %config = $config->getall();
    return \%config;
}

1;
