use strict;
use warnings;
use Test::More tests => 10;
use Log::Handler;

my $log = Log::Handler->new();
$log->config(filename => \*DATA);
$log->info('info');

my $options_handler = shift @{$log->{levels}->{INFO}};
my $options_file    = $options_handler->{output};

my %compare_file = (
    permissions     => '0640',
    filename        => '*STDOUT',
    mode            => 'append',
);

my %compare_handler = (
    newline         => 1,
    timeformat      => '%b %d %H:%M:%S',
    message_layout  => '%T %H[%P] [%L] %p: %m',
    trace           => 0,
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

__END__
<file>
    <default>
        newline        = 1
        permissions    = 0640
        timeformat     = %b %d %H:%M:%S
        mode           = append
        message_layout = "%T %H[%P] [%L] %p: %m"
        trace          = 0
        debug_mode     = 2
    </default>
    <common>
        filename    = *STDOUT
        maxlevel    = info
        minlevel    = info
    </common>
</file>
