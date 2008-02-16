use strict;
use warnings;
use Test::More tests => 36;
use File::Spec;
use Log::Handler;

my $rand_num = int(rand(999999));
my $logfile  = File::Spec->catfile('t', "Log-Handler-$rand_num.log");
my $log      = Log::Handler->new(
    filename     => [ 't', "Log-Handler-$rand_num.log" ],
    permissions  => '0664',
    mode         => 'append',
    autoflush    => 0,
    timeformat   => '',
    maxlevel     => 'debug',
    minlevel     => 'emergency',
    fileopen     => 1,
    filelock     => 1,
    reopen       => 1,
    newline      => 1,
    prefix       => 'prefix [%L] ',
);

ok(1, "new");

# checking all parameter
my $log_params  = $log->{levels}->{DEBUG}->[0];
my $file_params = $log_params->{output};

ok($log_params->{debug_trace} eq "0", "checking param debug");
ok($log_params->{debug_mode} eq "1", "checking param debug_mode");
ok($log_params->{debug_skip} eq "0", "checking param debug_skip");
ok($log_params->{die_on_errors} eq "1", "checking param die_on_errors");
ok($log_params->{maxlevel} eq "7", "checking param maxlevel");
ok($log_params->{minlevel} eq "0", "checking param minlevel");
ok($log_params->{newline} eq "1", "checking param newline");
ok($log_params->{prefix}, "checking param prefix");
ok(ref($log_params->{message_order}) eq "ARRAY", "checking param message_order");
ok($log_params->{timeformat} eq "", "checking param timeformat");

ok($file_params->{autoflush} eq "0", "checking param autoflush");
ok($file_params->{filelock} eq "1", "checking param filelock");
ok($file_params->{filename} eq $logfile, "checking param filename");
ok($file_params->{fileopen} eq "1", "checking param fileopen");
ok($file_params->{inode} =~ /^\d+\z/, "checking param inode");
ok(ref($file_params->{fh}) eq "GLOB", "checking param fh");
ok($file_params->{mode}, "checking param mode");
ok($file_params->{permissions} eq "436", "checking param permissions");
ok($file_params->{reopen} eq "1", "checking param reopen");
ok($file_params->{utf8} eq "0", "checking param utf8");

# checking all log methods
ok($log->debug("debug"), "checking debug") if $log->is_debug;
ok($log->info("info"), "checking info") if $log->is_info;
ok($log->notice("notice"), "checking notice") if $log->is_notice;
ok($log->warning("warning"), "checking warning") if $log->is_warning;
ok($log->error("error"), "checking error") if $log->is_error;
ok($log->err("error"), "checking err") if $log->is_err;
ok($log->critical("critical"), "checking critical") if $log->is_critical;
ok($log->crit("critical"), "checking crit") if $log->is_crit;
ok($log->alert("alert"), "checking alert") if $log->is_alert;
ok($log->emergency("emergency"), "checking emergency") if $log->is_emergency;
ok($log->emerg("emergency"), "checking emerg") if $log->is_emerg;

my $lines = 0;

open(my $fh, '<', $logfile) or do {
   ok(0, "open logfile");
   exit(1);
};

ok(1, "open logfile");

while (my $line = <$fh>) {
   next unless $line =~ /^prefix \[([A-Z]+)\] ([a-z]+)$/;
   my ($x, $y) = ($1, $2);
   $x = lc($x);
   next unless $x eq $y;
   ++$lines;
}

close $fh;

if ($lines == 11) {
   ok(1, "checking logfile (11:$lines)");
} else {
   ok(0, "checking logfile (11:$lines)");
}

close($file_params->{fh}) or die $!;
ok(1, "close logfile");
unlink($logfile) or die $!;
ok(1, "unlink logfile");
