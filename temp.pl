#!/usr/bin/perl
use LWP::UserAgent;
use Time::Local;
$sensor_temp = "";
$attempts = 0;
$temperature = 0;
$temperature2 = 0;
$pvoutput_api ="5f600268ece89c7ec404d471550a93cc7c40962d";
$pvoutport_systemid = "35607";
#$time = timelocal($sec,$min,$hour,$mday,$mon,$year);
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
$year += 1900;
$mon += 1;
$date = sprintf "%04d%02d%02d", $year,$mon,$mday;
$ptime = sprintf "%02d:%02d", $hour, $min;
$mqtt=0;
$mqtt2=0;
$mqtt3=0;


while ($sensor_temp !~ /YES/g && $attempts < 5)
{
        $sensor_temp = `cat /sys/bus/w1/devices/28-031*/w1_slave 2>&1`;
        if ($sensor_temp =~ /No such file or directory/)
        {
                last;
        }
        elsif ($sensor_temp !~ /NO/g)
        {
                $sensor_temp =~ /t=(\d+)/i/1000;
                $temperature = ($1)/1000;
}
        $attempts++;
}
while ($sensor_temp !~ /YES/g && $attempts < 5)
{
        $sensor_temp = `cat /sys/bus/w1/devices/28-011591*/w1_slave 2>&1`;
        if ($sensor_temp =~ /No such file or directory/)
        {
                last;
        }
        elsif ($sensor_temp !~ /NO/g)
        {
                $sensor_temp =~ /t=(\d+)/i/1000;
                $temperature2 = ($1)/1000;
}
        $attempts++;
}

#print "$temperature\n";
$temperature = sprintf "%.1f", $temperature;
$temperature2 = sprintf "%.1f", $temperature2;
$mqtt = qq('{"idx":25,"nvalue":0,"svalue":");
$mqtt2 = qq("}');
$mqtt3 = sprintf "%s%s%s%s","/usr/bin/mosquitto_pub -h 192.168.1.2  -t 'domoticz/in' -m ", $mqtt,$temperature2,$mqtt2;
#print "$temperature\n";
#print "$temperature2\n";
#print "$mqtt3\n";
#system ("$mqtt3"); 

my $ua = new LWP::UserAgent;
    $ua->default_header( 'X-Pvoutput-Apikey' => $pvoutput_api, 'X-Pvoutput-SystemId' => $pvoutport_systemid );
{

    my $response
    = $ua->post('http://pvoutput.org/service/r2/addstatus.jsp',
    {      
     	'd' => $date,
     	't' => $ptime,
	'v7' => $temperature,
	'v8' => $temperature2
    });
    my $content = $response->content;
    if ($debug == 1) {
        print "$content\n";
    }
    if ($response->is_error) {
        print "Error updating pvoutput.org $content\r\n";
    }
}
system ("$mqtt3");
#print "$mqtt3\n";

