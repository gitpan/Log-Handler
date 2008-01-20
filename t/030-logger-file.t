use strict;
use warnings;
use Test::More tests => 5;
use File::Spec;
use Log::Handler::Logger::File;

my $rand_num = int(rand(999999));
my $logfile  = File::Spec->catfile('t', "Log-Handler-$rand_num.log");
my $log      = Log::Handler::Logger::File->new(
    filename     => $logfile,
    permissions  => '0664',
    mode         => 'append',
    autoflush    => 0,
    fileopen     => 0,
    filelock     => 0,
    reopen       => 0,
);

ok(1, 'new');

# write a string to the file
$log->write("test\n") or die $!;
ok(1, "checking write");

# checking if the file is readable
open(my $fh, '<', $logfile) or do {
   ok(0, "open logfile ($logfile)");
   exit(1);
};

ok(1, "open logfile ($logfile)");

my $line = <$fh>;
chomp($line);
close $fh;

ok($line =~ /^test\z/, "checking logfile ($line)");

if ( unlink($logfile) ) {
    ok(1, "unlink logfile ($logfile)");
} else {
    ok(0, "unlink logfile ($logfile)");
}
