#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

use Roku::RokuLCD;

plan tests => 2;

sub connect_to_soundbridge {
    my ($roku) = @_;

    my $rcp = Roku::RokuLCD->new($roku, model => 400, debug => 1);
	if ($rcp) {
	    my $msg = "Success! Connected to $roku";
	    my $rv = $rcp->marquee(text => $msg);
	    pass("$msg [return value = '$rv']");
	    return($rcp);
	}
	else {
		fail("Couldn't connect to $roku");
        #diag "$_ appears on lines @{$violated{$_}}" for keys %violated;
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


my $rokuIP = 'roku';

TODO: {
	my $connection = connect_to_soundbridge($rokuIP);

  	if ($connection) {
        if ($connection->onstandby) { print "Off\n"; } else { print "On\n"; }
#        test_ticker($connection);
#       $connection->command('quit');
  		$connection->command("displaytype");
  		print map "$_\n", $connection->response();

#        $connection->ticker(text => "Ticker is an alternative to the marquee function - timings for M400 only");
        $connection->teletype(text => "Teletype is another alternative to the marquee function\n - Timings for M400 only");

#  		print "\n1\n";
#  		$connection->command("ps");
#  		print map "$_\n", $connection->response();
#  		print "\n2\n";
#  		#print $connection->message();
#  		#print map "$_\n", @msg;
#  		# end with a tidy up
#        $connection->marquee(text => "Byee", clear => 1);
#        print "here:\n";
#        $connection->command("ps");
#        print map "$_\n", $connection->sb_response;
        $connection->command('sketch -c exit');
        $connection->Quit();
  	}
}
    
    
    