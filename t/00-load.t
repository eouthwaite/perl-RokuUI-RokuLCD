#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'RokuUI::RokuLCD' ) || print "Bail out!\n";
}

diag( "Testing RokuUI::RokuLCD $RokuUI::RokuLCD::VERSION, Perl $], $^X" );
