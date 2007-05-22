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
        'Devel::Backtrace' => 0.03,
        'File::stat'       => 0,
        'File::Spec'       => 0,
        'Params::Validate' => 0,
        'Test::More'       => 0,
        Carp             => 0,
    },
    recommends         => {},
    sign               => 0,
);
$build->create_build_script;
