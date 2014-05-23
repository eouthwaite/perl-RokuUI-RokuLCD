#!perl -T
use v5.10.1;
use strict;
use warnings FATAL => 'all';
use Test::More;

use Roku::LCD;

plan tests => 6;

sub validate_roku_address {
    my ($roku_address) = @_;

    if ($roku_address =~ /^([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])$/) {
        # Unqualified hostname
        return($1);
    }
    elsif ($roku_address =~ /^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$/) {
        # ValidIpAddressRegex from smink @ stackoverflow
        return($1);
    }
    elsif ($roku_address =~ /^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$/) {
        # ValidHostnameRegex from smink @ stackoverflow
        return($1);
    }
    return;
}


sub connect_to_soundbridge {
    my ($roku, $model) = @_;

    ok ( my $rcp = Roku::LCD->new($roku, model => $model, debug => 1), "Connect to Soundbridge '$roku'");
    if ($rcp) {
        return($rcp);
    }
}

my $connection;
my $rokuIP;
SKIP: {
    skip 'No Roku Soundbridge to test against', 1
        unless ($ENV{ROKUIP});

    $rokuIP = validate_roku_address($ENV{ROKUIP});
    ok( defined $rokuIP, 'Able to take Roku address from environment variable');
}

SKIP: {
    skip 'No Roku Soundbridge to test against', 1
        unless ($rokuIP);

    diag( "Testing M400 against Roku Address '$rokuIP'" );
    $connection = connect_to_soundbridge($rokuIP, 400);
}

SKIP: {
    skip 'Not connected to a Roku Soundbridge', 1
        unless ($connection);
    is( length ( $connection->_spacefill(text => 'A')) , 16, 'Spacefill creates the right sized text for M400' ); 
    $connection->Quit;
}

SKIP: {
    skip 'No Roku Soundbridge to test against', 1
        unless ($rokuIP);

    diag( "Testing M500 against Roku Address '$rokuIP'" );
    $connection = connect_to_soundbridge($rokuIP, 500);
}

SKIP: {
    skip 'Not connected to a Roku Soundbridge', 1
        unless ($connection);
    is( length ( $connection->_spacefill(text => 'A')) , 40, 'Spacefill creates the right sized text for M500' ); 
    $connection->Quit;
}

SKIP: {
    skip 'No Roku Soundbridge to test against', 1
        unless ($rokuIP);

    diag( "Testing M600 against Roku Address '$rokuIP'" );
    eval { $connection = Roku::LCD->new($rokuIP, model => 600, debug => 1) } or my $response = $@;
    like($response, qr/Unrecognised model type/, "Connect to unknown Soundbridge model M600 fails");

}


