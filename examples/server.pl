#!/usr/bin/perl
use strict;
use warnings;
use IO::Socket::INET;
use Log::Handler::Output::File;

my $sock = IO::Socket::INET->new(
    LocalAddr => '127.0.0.1',
    LocalPort => 44444,
    Listen    => 1,
) or die $!;

my $file = Log::Handler::Output::File->new(
    filename => 'server.log',
    mode     => 'append',
    fileopen => 1,
    reopen   => 1,
);

while ( 1 ) {
    $file->log(message => "waiting for next connection\n");

    while (my $request = $sock->accept) {
        my $ipaddr = sprintf('%-15s', $request->peerhost);
        while (my $message = <$request>) {
            $file->log(message => "$ipaddr - $message");
        }
    }
}
