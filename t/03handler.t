use strict;
use warnings;
use Test::More tests => 16;
use File::Spec;
use Log::Handler;

my $logfile = File::Spec->catfile('t', 'Log-Handler-Test-File.log');

my $log = Log::Handler->new(
   filename => $logfile,
   permissions => '0664',
   mode => 'append',
   autoflush => 1,
   timeformat => '',
   maxlevel => 0,
   minlevel => 7,
   fileopen => 1,
   filelock => 1,
   reopen => 1,
   newline => 1,
   prefix => 'test [<--LEVEL-->] ',
);

ok(1, "new");

ok($log->debug("debug"), "checking debug")
   if $log->would_log_debug();

ok($log->info("info"), "checking info")
   if $log->would_log_info();

ok($log->notice("notice"), "checking notice")
   if $log->would_log_notice();

ok($log->note("note"), "checking note")
   if $log->would_log_note();

ok($log->warning("warning"), "checking warning")
   if $log->would_log_warning();

ok($log->error("error"), "checking error")
   if $log->would_log_error();

ok($log->err("err"), "checking err")
   if $log->would_log_err();

ok($log->critical("critical"), "checking critical")
   if $log->would_log_critical();

ok($log->crit("crit"), "checking crit")
   if $log->would_log_crit();

ok($log->alert("alert"), "checking alert")
   if $log->would_log_alert();

ok($log->emergency("emergency"), "checking emergency")
   if $log->would_log_emergency();

ok($log->emerg("emerg"), "checking emerg")
   if $log->would_log_emerg();

$log->CLOSE();

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

if ($lines == 12) {
   ok(1, "checking logfile ($lines)");
} else {
   ok(0, "checking logfile ($lines)");
}

ok(unlink($logfile), "unlink logfile");
