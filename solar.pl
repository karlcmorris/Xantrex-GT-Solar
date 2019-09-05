#!/usr/bin/perl
#use Device::SerialPort;
use LWP::UserAgent;
use Time::Local;
use HTTP::Status qw(:constants :is status_message);
$debug = 0;
$submit = 1;
$serial_port = "/dev/ttyUSB0";
$pvoutput_api ="5f600268ece89c7ec404d471550a93cc7c40962d";
$pvoutport_systemid = "35607";
 
$serial_lock = "/tmp/ttyUSB0.lock";
 
## Wait until unlocked
while (-e $serial_lock)
{
  sleep (1);
}
$serial_port = new Device::SerialPort ($serial_port, "", $serial_lock);
 
$serial_port->baudrate(9600)             || die "failed setting baudrate";
$serial_port->parity("none")             || die "failed setting parity";
$serial_port->databits(8)                || die "failed setting databits";
$serial_port->handshake("none")          || die "failed setting handshake";
$serial_port->write_settings             || die "no settings";
 
## Might need to tweak this if data is truncated.
$serial_port->read_const_time(1000);
 
$serial_port->write("INV?\r");
($count, $xantrex_status) = $serial_port->read(255);
$serial_port->write("KWHTODAY?\r");
($count, $xantrex_kwhtoday) = $serial_port->read(255);
$serial_port->write("TIME?\r");
($count, $xantrex_time) = $serial_port->read(255);
$serial_port->write("POUT?\r");
($count, $xantrex_pout) = $serial_port->read(255);
$serial_port->write("VOUT?\r");
($count, $xantrex_VAC) = $serial_port->read(255);
$serial_port->write("MEASTEMP?\r");
($count, $xantrex_HSTemp) = $serial_port->read(255); 
$xantrex_HSTemp = substr $xantrex_HSTemp, 2, 4;

$serial_port->close || warn "close failed";
 
$xantrex_wtoday =  $xantrex_kwhtoday * 1000;
#$time = timelocal($sec,$min,$hour,$mday,$mon,$year);
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
$year += 1900;
$mon += 1;
$date = sprintf "%04d%02d%02d", $year,$mon,$mday;
$ptime = sprintf "%02d:%02d", $hour, $min;

if ($xantrex_pout < 15) {$xantrex_pout = 0;}

 
if ($debug == 1) {
    print "Current date/time is: $date - $ptime\n";
    print "Current inverter status is: $xantrex_status\n";
    print "Total KWH today is: $xantrex_kwhtoday\n";
    print "Total WH today is: $xantrex_wtoday\n";
    print "Current output is: $xantrex_pout\n";
    print "Inverter AC output: $xantrex_VAC\n";
    print "Inverter Temperature: $xantrex_HSTemp\n";
}
chomp($xantrex_status);
my $length = length($xantrex_status);
$length -=1;
$status = substr $xantrex_status, 0, $length;
if (($submit == 1)  && ($status eq "ON")) {
    if ($debug == 1) {
        print  "Submitting data\n";
    }
    my $ua = new LWP::UserAgent;
    $ua->default_header( 'X-Pvoutput-Apikey' => $pvoutput_api, 'X-Pvoutput-SystemId' => $pvoutport_systemid );
 
 
    my $response 
    = $ua->post('http://pvoutput.org/service/r2/addstatus.jsp', 
    { 'v2' => $xantrex_pout, 
     'v1' => $xantrex_wtoday,
     'd' => $date,
     't' => $ptime,
     'v5' => $xantrex_HSTemp,
     'v6' => $xantrex_VAC
    });
    my $content = $response->content;
    if ($debug == 1) {
        print "$content\n";
    }
    if ($response->is_error) {
        print "Error updating pvoutput.org $content\r\n";
    }

$solar1 = sprintf "%.0f",$xantrex_pout;
$volts = sprintf "%.0f",$xantrex_VAC;
$itemp = sprintf "%.0f",$xantrex_HSTemp;
#$mqtt = qq('{"idx":114,"nvalue":0,"svalue":");
#$mqtt2 = qq("}');
#$mqtt3 = sprintf "%s%s%s%s","/usr/bin/mosquitto_pub -h 192.168.1.2  -t 'domoticz/in' -m ", $mqtt,$solar1,$mqtt2;
#print "$solar1\n";
#print "$mqtt3\n";

$xmqtt = qq('{"idx":115,"nvalue":0,"svalue":");
$xmqtt2 = qq("}');
$xmqtt3 = sprintf "%s%s%s%s","/usr/bin/mosquitto_pub -h 192.168.1.2  -t 'domoticz/in' -m ", $xmqtt,$volts,$xmqtt2;

$imqtt = qq('{"idx":116,"nvalue":0,"svalue":");
$imqtt2 = qq("}');
$imqtt3 = sprintf "%s%s%s%s","/usr/bin/mosquitto_pub -h 192.168.1.2  -t 'domoticz/in' -m ", $imqtt,$itemp,$imqtt2;


system ("$mqtt3");
system ("$xmqtt3");
system ("$imqtt3");


}

