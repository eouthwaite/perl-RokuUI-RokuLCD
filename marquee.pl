#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

use Roku::RokuLCD;

plan tests => 1;

sub connect_to_soundbridge {
    my ($roku) = @_;

    my $rcp = Roku::RokuLCD->new($roku, model => 400);
	if ($rcp) {
	    my $msg = "Success! Connected to $roku";
	    $rcp->command('sketch');
	    $rcp->command('clear');
	    $rcp->command("marquee -start \"$msg\"");
	    sleep(10);
	    $rcp->Quit();
	    pass($msg);
	}
	else {
		fail("Couldn't connect to $roku");
        #diag "$_ appears on lines @{$violated{$_}}" for keys %violated;
	}

#my($rv) = $display->marquee(text => "This allows easy access to the marquee function - timings for M400 only");
}


my $rokuIP = 'roku';

TODO: {
  connect_to_soundbridge($rokuIP);
}
    
    
    