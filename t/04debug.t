use strict;
use warnings;
use Test::More tests => 2;

foreach my $mode (1, 2) {
   eval "use Log::Handler debug => $mode;";
   if ($@) {
      ok(0, "checking debug mode $mode");
      die $@;
   } else {
      ok(1, "checking debug mode $mode");
   }
}
