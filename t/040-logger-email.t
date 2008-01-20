use strict;
use warnings;
use Test::More tests => 3;
use File::Spec;
use Log::Handler::Logger::Email;
$Log::Handler::Logger::Email::TEST = 1;

my $log = Log::Handler::Logger::Email->new(
    host     => [ 'bloonix.de' ],
    hello    => 'EHLO bloonix.de',
    timeout  => 60,
    debug    => 1,
    from     => 'jschulz.cpan@bloonix.de',
    to       => 'jschulz.cpan@bloonix.de',
    subject  => 'Log::Handler::Logger::Email test',
    buffer   => 20,
    interval => 0,
);

ok(1, 'new');

# checking all log levels for would()
foreach my $i (1..10) {
    $log->write("test $i\n") or die $!;
}
ok(1, "checking write()");

# checking all lines
my $match_lines = 0;
my $all_lines   = 0;

foreach my $line ( @{$log->{LINE_BUFFER}} ) {
    ++$all_lines;
    next unless $line =~ /^test \d+$/;
    ++$match_lines;
}

if ($match_lines == 10) {
   ok(1, "checking buffer ($all_lines:$match_lines)");
} else {
   ok(0, "checking buffer ($all_lines:$match_lines)");
}

