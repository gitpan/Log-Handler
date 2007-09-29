use strict;
use warnings;
use Test::More tests => 18;
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
   prefix       => 'test [<--LEVEL-->] ',
);

ok(1, "new");

ok($log->debug("debug"), "checking debug") if $log->is_debug;
ok($log->info("info"), "checking info") if $log->is_info;
ok($log->notice("notice"), "checking notice") if $log->is_notice;
ok($log->note("note"), "checking note") if $log->is_note;
ok($log->warning("warning"), "checking warning") if $log->is_warning;
ok($log->warn("warn"), "checking warn") if $log->is_warning;
ok($log->error("error"), "checking error") if $log->is_error;
ok($log->err("err"), "checking err") if $log->is_err;
ok($log->critical("critical"), "checking critical") if $log->is_critical;
ok($log->crit("crit"), "checking crit") if $log->is_crit;
ok($log->alert("alert"), "checking alert") if $log->is_alert;
ok($log->emergency("emergency"), "checking emergency") if $log->is_emergency;
ok($log->emerg("emerg"), "checking emerg") if $log->is_emerg;
ok($log->close, "checking close");

my $lines = 0;

open(my $fh, '<', $logfile) or do {
   ok(0, "open logfile");
   exit(1);
};

ok(1, "open logfile");

while (my $line = <$fh>) {
   chomp($line);
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
