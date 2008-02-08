use strict;
use warnings;
use Test::More tests => 30;
use Log::Handler;

my @LINES;
sub save_lines {
    push @LINES, $_[0]->{message};
}

my $log = Log::Handler->new();

$log->add(forward => {
    forward_to     => \&save_lines,
    maxlevel       => 'debug',
    minlevel       => 'emergency',
    message_layout => 'prefix [%L] %m postfix',
});

ok(1, 'new');

ok($log->is_debug,     'checking is_debug');
ok($log->is_info,      'checking is_info');
ok($log->is_notice,    'checking is_notice');
ok($log->is_note,      'checking is_note');
ok($log->is_warning,   'checking is_warning');
ok($log->is_warn,      'checking is_warn');
ok($log->is_error,     'checking is_error');
ok($log->is_err,       'checking is_err');
ok($log->is_critical,  'checking is_critical');
ok($log->is_crit,      'checking is_crit');
ok($log->is_alert,     'checking is_alert');
ok($log->is_emergency, 'checking is_emergency');
ok($log->is_emerg,     'checking is_emerg');
ok($log->is_fatal,     'checking is_fatal');

ok($log->debug('DEBUG'),         'checking debug');
ok($log->info('INFO'),           'checking info');
ok($log->notice('NOTICE'),       'checking notice');
ok($log->note('NOTICE'),         'checking note');
ok($log->warning('WARNING'),     'checking warning');
ok($log->warn('WARNING'),        'checking warn');
ok($log->error('ERROR'),         'checking error');
ok($log->err('ERROR'),           'checking err');
ok($log->critical('CRITICAL'),   'checking critical');
ok($log->crit('CRITICAL'),       'checking crit');
ok($log->alert('ALERT'),         'checking alert');
ok($log->emergency('EMERGENCY'), 'checking emergency');
ok($log->emerg('EMERGENCY'),     'checking emerg');
ok($log->fatal('FATAL'),         'checking fatal');

# checking all lines that should be forwarded
my $match_lines = 0;
my $all_lines   = 0;

foreach my $line ( @LINES ) {
    ++$all_lines;
    next unless $line =~ /^prefix \[([A-Z]+)\] ([A-Z]+) postfix$/;
    next unless $1 eq $2;
    ++$match_lines;
}

if ($match_lines == 14) {
   ok(1, "checking buffer ($all_lines:$match_lines)");
} else {
   ok(0, "checking buffer ($all_lines:$match_lines)");
}
