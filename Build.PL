use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    create_readme      => 1,
    create_makefile_pl => 'traditional',
    license            => 'perl',
    module_name        => 'Log::Handler',
    dist_author        => 'Jonny Schulz',
    requires => {
        'Devel::Backtrace' => 0.05,
        'File::Spec'       => 0,
        'Params::Validate' => 0,
        'Test::More'       => 0,
        Carp               => 0,
        'Sys::Hostname'    => 0,
        'Config::General'  => 0,
    },
    recommends         => {
        'Config::Properties' => 0,
        'YAML'               => 0
    },
    sign               => 0,
);
$build->create_build_script;
