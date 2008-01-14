use strict;
use warnings;
use Test::More tests => 40;
use File::Spec;
use Log::Handler;

my $logfile = File::Spec->catfile('t', 'Log-Handler-Test-File.log');

my $log = Log::Handler->new(
    filename     => $logfile,
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
    postfix      => ' postfix',
);

ok(1, "new");

# checking all parameter
my $params = $log->{levels}->{DEBUG}->[0];
ok($params->{autoflush} eq "0", "checking param autoflush");
ok($params->{debug} eq "0", "checking param debug");
ok($params->{debug_mode} eq "1", "checking param debug_mode");
ok($params->{debug_skip} eq "0", "checking param debug_skip");
ok($params->{die_on_errors} eq "1", "checking param die_on_errors");
ok(ref($params->{fh}) eq "GLOB", "checking param fh");
ok($params->{filelock} eq "1", "checking param filelock");
ok($params->{filename} eq "t/Log-Handler-Test-File.log", "checking param filename");
ok($params->{fileopen} eq "1", "checking param fileopen");
ok($params->{inode} =~ /^\d+\z/, "checking param inode");
ok($params->{maxlevel} eq "7", "checking param maxlevel");
ok($params->{minlevel} eq "0", "checking param minlevel");
ok($params->{mode}, "checking param mode");
ok($params->{newline} eq "1", "checking param newline");
ok($params->{permissions} eq "436", "checking param permissions");
ok($params->{prefix} eq "prefix [%L] ", "checking param prefix");
ok($params->{postfix} eq " postfix", "checking param prefix");
ok(ref($params->{prefixes}) eq "ARRAY", "checking param prefixes");
ok(ref($params->{postfixes}) eq "ARRAY", "checking param prefixes");
ok($params->{reopen} eq "1", "checking param reopen");
ok($params->{rewrite_to_stderr} eq "0", "checking param rewrite_to_stderr");
ok($params->{timeformat} eq "", "checking param timeformat");
ok($params->{utf8} eq "0", "checking param utf8");

# checking all log methods
ok($log->debug("debug"), "checking debug") if $log->is_debug;
ok($log->info("info"), "checking info") if $log->is_info;
ok($log->notice("notice"), "checking notice") if $log->is_notice;
ok($log->note("notice"), "checking note") if $log->is_note;
ok($log->warning("warning"), "checking warning") if $log->is_warning;
ok($log->warn("warning"), "checking warn") if $log->is_warning;
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
   next unless $line =~ /^prefix \[([A-Z]+)\] ([a-z]+) postfix$/;
   my ($x, $y) = ($1, $2);
   $x = lc($x);
   next unless $x eq $y;
   ++$lines;
}

close $fh;

if ($lines == 13) {
   ok(1, "checking logfile ($lines)");
} else {
   ok(0, "checking logfile ($lines)");
}

ok(unlink($logfile), "unlink logfile");
