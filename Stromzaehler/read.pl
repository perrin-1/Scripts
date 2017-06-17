#!/usr/bin/perl
#
# Holt die Daten vom SML-Zaehler Easymeter Q3C
# es wird die obere optische Schnittstelle ausgelesen
# dort liefert der Zaehler alle 2sec. einen Datensatz
# wird von CRON jede Minute aufgerufen
# http://wiki.volkszaehler.org/software/sml
# 03.2012 by NetFritz
# 07.2013 by Ollir

# ========================================
sub hexstr_to_signed32int {
    my ($hexstr) = @_;
     print "Invalid hex string: $hexstr"

        if $hexstr !~ /^[0-9A-Fa-f]/;
        #if $hexstr !~ /^[0-9A-Fa-f]{1,8}$/;

    my $num = hex($hexstr);
    my $int;

    $int = $num >> 31 ? $num - 2 ** 32 : $num;
    #print "Int: " . $int . "\n";
    return $int;
}


# ========================================
#
use Device::SerialPort;
my @port = (
	{ Name => 'Strom-Haus', Obj => Device::SerialPort->new("/dev/ttyUSB0") },
	{ Name => 'Strom-Heizung', Obj => Device::SerialPort->new("/dev/ttyUSB1") }
	);
#print (@port);


foreach my $lport (@port) {
	$lport->{Obj}->databits(8);
	$lport->{Obj}->baudrate(9600);
	$lport->{Obj}->parity("none");
	$lport->{Obj}->stopbits(1);
	$lport->{Obj}->handshake("none");
	$lport->{Obj}->write_settings;
	$lport->{Obj}->purge_all();
	$lport->{Obj}->read_char_time(0);     # don't wait for each character
	$lport->{Obj}->read_const_time(1000); # 1 second per unfulfilled "read" call
}

#
# OBIS-Kennzahl und Anzahl der Zeichen von Anfang OBIS bis Messwert,
# Messwertwertlaenge  8-10 Zeichen

%channel = (
  'Verbrauch' => ['070100010800FF',18,10,10000], # 1-0:1.8.0  /* kWh aufgenommen */
  'Leistung' => ['0701000F0700FF',14,8,10]   # 1-0:15.7.0 /* Wirkleistung aktuell */
);

# von der schnittstelle lesen
#print scalar localtime();
#print "\n"; 

foreach my $lport (@port) {

for($i=0;$i<=5;$i++) {
        # wenn 540 chars gelesen werden wird mit last
        # abgebrochen, wenn nicht wird Schleife 2 mal widerholt
         my ($count,$saw)=$lport->{Obj}->read(540);   # will read 540 chars
         if ($count >300) {
			#print "\n".$lport->{Name}."=";
                        #print  "read $count chars\n";
                my $x=uc(unpack('H*',$saw)); # nach hex wandeln
                        #print  "$count <> $x\n";  # gibt die empfangenen Daten in Hex aus

                while (($uuid) = each(%channel)){
                        $key =  $channel{$uuid}[0] ;
                        $pos =  $channel{$uuid}[1] ;
                        $len =  $channel{$uuid}[2] ;
			$scaler =  $channel{$uuid}[3] ;
                        #print "uuid=$uuid , key=$key, pos=$pos, len=$len\n" ;

                        # Stringpos raussuchen
                        $pos1=index($x,$key);

                        # grob rausschneiden
                        $val1 = substr( $x , $pos1  , 50);
                        #print $key . " = " . $val1  . "\n";

                        # Messwert selber
                        $val2 = substr( $val1 , length($key) + $pos , $len);
			#print "Messwert Hex " . $val2 . "\n";

                        # Wert umwandeln
                        $val3 =  hexstr_to_signed32int($val2)/$scaler;
                        print $lport->{Name}."-".$uuid . "=" . $val3 . "\n";

                        # Wert im Hash ablegen
                        #$channel{$uuid}[3] = $val3 ;
                }
		#print "|";
                last; # while verlassen
         } else {
                #print "Schnittstellenlesefehler redu = $i ; count = $count <> \n";
         }
}
}
