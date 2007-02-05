use strict;
use warnings;
use Test::More qw(no_plan);
use Log::Handler;

my $logfile = './t/Log-Handler-Test-File.log';

my $log = Log::Handler->new(
   filename => $logfile,
   permissions => '0664',
   mode => 'append',
   autoflush => 1,
   timeformat => '%b %d %H:%M:%S',
   maxlevel => 0,
   minlevel => 7,
   fileopen => 1,
   filelock => 1,
   reopen => 1,
   newline => 1,
   prefix => '[<--LEVEL-->] ',
);

ok(1, "new");

ok($log->debug("this is a debug message"), "checking debug")
   if $log->would_log_debug();

ok($log->info("this is a info message"), "checking info")
   if $log->would_log_info();

ok($log->notice("this is a notice"), "checking notice")
   if $log->would_log_notice();

ok($log->note("this is a notice as well"), "checking note")
   if $log->would_log_note();

ok($log->warning("this is a warning"), "checking warning")
   if $log->would_log_warning();

ok($log->error("this is a error message"), "checking error")
   if $log->would_log_error();

ok($log->err("this is a error message as well"), "checking err")
   if $log->would_log_err();

ok($log->critical("this is a critical message"), "checking critical")
   if $log->would_log_critical();

ok($log->crit("this is a critical message as well"), "checking crit")
   if $log->would_log_crit();

ok($log->alert("this is a alert message"), "checking alert")
   if $log->would_log_alert();

ok($log->emergency("this is a emergency message"), "checking emergency")
   if $log->would_log_emergency();

ok($log->emerg("this is a emergency message as well"), "checking emerg")
   if $log->would_log_emerg();

my $exidence = qr/^\w\w\w \d\d \d\d:\d\d:\d\d \[DEBUG\] this is a debug message
\w\w\w \d\d \d\d:\d\d:\d\d \[INFO\] this is a info message
\w\w\w \d\d \d\d:\d\d:\d\d \[NOTICE\] this is a notice
\w\w\w \d\d \d\d:\d\d:\d\d \[NOTE\] this is a notice as well
\w\w\w \d\d \d\d:\d\d:\d\d \[WARNING\] this is a warning
\w\w\w \d\d \d\d:\d\d:\d\d \[ERROR\] this is a error message
\w\w\w \d\d \d\d:\d\d:\d\d \[ERR\] this is a error message as well
\w\w\w \d\d \d\d:\d\d:\d\d \[CRITICAL\] this is a critical message
\w\w\w \d\d \d\d:\d\d:\d\d \[CRIT\] this is a critical message as well
\w\w\w \d\d \d\d:\d\d:\d\d \[ALERT\] this is a alert message
\w\w\w \d\d \d\d:\d\d:\d\d \[EMERGENCY\] this is a emergency message
\w\w\w \d\d \d\d:\d\d:\d\d \[EMERG\] this is a emergency message as well
$/;

open my $fh, '<', $logfile or die $!;
local $/;
my $fileout = <$fh>;
print $fileout;
close $fh;

ok($fileout =~ /$exidence/, "checking logfile");
unlink($logfile)
   if -e $logfile;
