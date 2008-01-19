use strict;
use warnings;
use Test::More tests => 20;
use File::Spec;
use Log::Handler::Logger;

my @LINES;
sub save_lines {
    push @LINES, $_[0];
}

my $log = Log::Handler::Logger->new(Forward => {
    forward_to   => [ \&save_lines ],
    maxlevel     => 'debug',
    minlevel     => 'emergency',
    timeformat   => '',
    prefix       => 'prefix [%L] ',
    postfix      => ' postfix',
});

ok(1, 'new');

my @test_level = qw(
    DEBUG
    INFO
    NOTICE
    WARNING
    ERROR
    CRITICAL
    ALERT
    EMERGENCY
    FATAL
);

# checking all log levels for would()
foreach my $level (@test_level) {
    my $ret = $log->would_log($level);
    ok($ret, "checking would($level)");
}

# checking all log levels for write()
foreach my $level (@test_level) {
    my $ret = $log->write($level, $level);
    ok($ret, "checking write($level)");
}

# checking all lines that should be forwarded
my $match_lines = 0;
my $all_lines   = 0;

foreach my $line ( @LINES ) {
    ++$all_lines;
    next unless $line =~ /^prefix \[([A-Z]+)\] ([A-Z]+) postfix$/;
    next unless $1 eq $2;
    ++$match_lines;
}

if ($match_lines == 9) {
   ok(1, "checking buffer ($all_lines:$match_lines)");
} else {
   ok(0, "checking buffer ($all_lines:$match_lines)");
}
