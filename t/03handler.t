use strict;
use warnings;
use Test::More tests => 38;
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
   prefix       => 'test [%L] ',
);

ok(1, "new");

my $params = $log->{levels}->{DEBUG}->[0];

ok($params->{autoflush} eq "0", "checking self autoflush");
ok($params->{debug} eq "0", "checking self debug");
ok($params->{debug_mode} eq "1", "checking self debug_mode");
ok($params->{debug_skip} eq "0", "checking self debug_skip");
ok($params->{die_on_errors} eq "1", "checking self die_on_errors");
ok(ref($params->{fh}) eq "GLOB", "checking self fh");
ok($params->{filelock} eq "1", "checking self filelock");
ok($params->{filename} eq "t/Log-Handler-Test-File.log", "checking self filename");
ok($params->{fileopen} eq "1", "checking self fileopen");
ok($params->{inode} =~ /^\d+\z/, "checking self inode");
ok($params->{maxlevel} eq "7", "checking self maxlevel");
ok($params->{minlevel} eq "0", "checking self minlevel");
ok($params->{mode} eq "1089", "checking self mode");
ok($params->{newline} eq "1", "checking self newline");
ok($params->{permissions} eq "436", "checking self permissions");
ok($params->{prefix} eq "test [%L] ", "checking self prefix");
ok(ref($params->{prefixes}) eq "ARRAY", "checking self prefixes");
ok($params->{reopen} eq "1", "checking self reopen");
ok($params->{rewrite_to_stderr} eq "0", "checking self rewrite_to_stderr");
ok($params->{timeformat} eq "", "checking self timeformat");
ok($params->{utf8} eq "0", "checking self utf8");

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
   next unless $line =~ /^test \[([A-Z]+)\] ([a-z]+)$/;
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
