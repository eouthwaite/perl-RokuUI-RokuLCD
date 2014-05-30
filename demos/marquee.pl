#!perl -T
use v5.10.1;
use strict;
use warnings FATAL => 'all';
use Test::More;

use Roku::LCD;

plan tests => 2;

sub connect_to_soundbridge {
    my ($roku) = @_;

    my $rcp = Roku::LCD->new(Host => $roku, debug => 1);
	if ($rcp) {
	    my $msg = "Success! Connected to $roku";
	    my $rv = 12;
#	    my $rv = $rcp->marquee(text => $msg);
	    pass("$msg [return value = '$rv']");
	    return($rcp);
	}
	else {
		fail("Couldn't connect to $roku");
	}
}


sub test_marquee {
    my ($rcp) = @_;

	my($rv) = $rcp->marquee(text => "This allows easy access to the marquee function - timings for M400 only");	
}

sub test_ticker {
    my ($rcp) = @_;

    my($rv) = $rcp->ticker(text => "Ticker is an alternative to the marquee function - timings for M400 only");
}

sub test_teletype {
    my ($rcp) = @_;

    my($rv) = $rcp->teletype(text => "Teletype is an alternative to the marquee function - timings for M400 only");
}


my $rokuIP = 'roku';

TODO: {
	my $connection = connect_to_soundbridge($rokuIP);

  	if ($connection) {
        if ($connection->onstandby) { print "Off\n"; } else { print "On\n"; }
        #test_ticker($connection);
  		$connection->command("displaytype");
  		print map "$_\n", $connection->response();

        #$connection->ticker(text => "Ticker is an alternative to the marquee function - timings for M400 only");
        #$connection->teletype(text => "Teletype is another alternative to the marquee function\n - Timings for M400 only");

        $connection->Quit();
  	}
}
    
    
    