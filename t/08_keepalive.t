#!/usr/bin/env perl6

use lib 't/lib';
use starter;
use Test;

plan 6;

my $s = srv;
my $l = 0;
$s.register(sub ($req, $res, $n) {
  $res.close('res1') if $l == 0;
  $n(True) if ++$l >= 0;
});
$s.register(sub ($req, $res, $n) {
  $res.headers<Connection> = 'close' if $l == 2;
  $res.close('res2') if $l == 2;
  $res.close('improper response', force => True) if $l != 2;
});

$s.listen;
my $r = req;
$r.send("GET /a HTTP/1.0\r\nConnection: keep-alive\r\n\r\n");
my $data;
while (my $u = $r.recv) {
  $data ~= $u;
  last if $data.match( 'res1' );
}
ok ($data.match(/ ^^ 'res1' $$ /) ?? True !! False), 'Testing for pipelined response #1';
ok (!$data.match(/ ^^ 'res2' $$ /) ?? True !! False), 'Testing #1 for *only* #1';
ok (!$data.match(/ ^^ 'improper' $$ /) ?? True !! False), 'Testing #1 for *only* #1';
$r.send("GET /b HTTP/1.0\r\n\r\n");
$data = '';
while ($u = $r.recv) {
  $data ~= $u;
}
ok ($data.match(/ ^^ 'res2' $$ /) ?? True !! False), 'Testing for pipelined response #2';
ok (!$data.match(/ ^^ 'res1' $$ /) ?? True !! False), 'Testing #2 for *only* #2';
ok (!$data.match(/ ^^ 'improper' $$ /) ?? True !! False), 'Testing #2 for *only* #2';
