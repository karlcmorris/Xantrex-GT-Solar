#!/usr/bin/perl -w
#
use strict;
my $url = 'http://192.168.1.52:8080/sensor/';
my $fid = '5e4859a437fa3cb8824abfbc3680946a';
my $prm = '\?version=1.0\&interval=minute\&unit=watt\&jsonp_callback=realtime';
my $result = qx(/usr/bin/curl -s $url$fid$prm);
my @array = split(/[\[\]]/, $result);
my $last = 0;
foreach (@array)
{
if( $_ =~ /[0-9]+\,[0-9]+/ )
{
my @C = split(/,/);
my $DATETIME = $C[0];
my $VALUE = $C[1];
$last = $C[1];
}
}

if ($last > 5000) {
print "0";
} else {
print "$last\n";

my $usage = sprintf "%.1f", $last;
my $mqtt = qq('{"idx":117,"nvalue":0,"svalue":");
my $mqtt2 = qq("}');
my $mqtt3 = sprintf "%s%s%s%s","/usr/bin/mosquitto_pub -h 192.168.1.2  -t 'domoticz/in' -m ", $mqtt,$usage,$mqtt2;
system ("$mqtt3");


}
