use strict;
use warnings;
use Test::More tests => 8;
use Log::Handler;

my %config = (
    file => {
        default => {
            newline        => 1,
            timeformat     => '%b %d %H:%M:%S',
            mode           => 'excl',
            message_layout => '%T %H[%P] [%L] %S: %m',
            debug_mode     => 2,
            fileopen       => 0,
        },
        common => {
            filename => 'foo',
            maxlevel => 'info',
            minlevel => 'info',
            newline  => 0,
        }
    }
);

my $log = Log::Handler->new();
$log->config(config => \%config);

my $options_handler = shift @{$log->{levels}->{INFO}};
my $options_file    = $options_handler->{output};

my %compare_file = (
    filename => 'foo',
    fileopen => 0,
);

my %compare_handler = (
    newline         => 0,
    timeformat      => '%b %d %H:%M:%S',
    message_layout  => '%T %H[%P] [%L] %S: %m',
    debug_mode      => 2,
    maxlevel        => 6,
    minlevel        => 6,
);

while (my ($k, $v) = each %compare_file) {
    my $ret = exists $options_file->{$k} && $options_file->{$k} eq $v;
    ok($ret, "checking option $k ($v:$options_file->{$k})");
}

while (my ($k, $v) = each %compare_handler) {
    my $ret = exists $options_handler->{$k} && $options_handler->{$k} eq $v;
    ok($ret, "checking option $k ($v:$options_handler->{$k})");
}
