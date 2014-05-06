#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';

use Roku::RokuLCD;

my $self = Roku::RokuLCD->new('roku', model => 400, debug => 1);
if ($self) {



  my $text    = "This allows easy access to the marquee function - timings for M400 only";
  my $pause   = 1;
  my $y       = 0;
  my $dlength = 16;
  my $rc;
  my $offset = 0;
  my $tlength = 0;
  my $dtext = 0;
  my $dur = 0;
  my $spc = 0;
  
    # only take over if on standby
    if ($self->onstandby) {
        $self->command('sketch');
#        if ($clear) { $self->command('clear'); }
  print "\nticker:\n\$text$text\n\$pause$pause\n\$y$y\n\$dlength$dlength\n\$offset$offset\n\$tlength$tlength\n\$dtext$dtext\n\$dur$dur\n\$spc$spc\n";
  
#  my ($dtext,$dur,$offset,$spc,$tlength) = 0;
  for (my $length=1;$length<(length($text));$length++) {
    $spc++;
    $tlength++ unless ($tlength == $dlength);
    $offset++ if (length($dtext) == $dlength);
    $dtext = substr($text,$offset,$tlength);
    $spc = 0 if (substr($dtext,-1,1) eq ' ');

  print "\nticker loop1:\n\$length$length\n\$spc$spc\n\$y$y\n\$dlength$dlength\n\$offset$offset\n\$tlength$tlength\n\$dtext$dtext\n\$dur$dur\n\$spc$spc\n";

    if ((length($text) > $dlength) && (++$dur == $dlength)) {
      print "length > dlength && dur == dlength\n";
      $rc = $self->_text(text => $dtext, duration => 1, y => $y);
      if (${*$self}{debug}) { print "DEBUG dtext='$dtext' dur='$dur' spc='$spc'\n"; }
      $dur = $spc;
      $dur = 0 if ($dur > $dlength);
    }
    else {
      print "length <= dlength || dur != dlength\n";
      $rc = $self->_text(text => $dtext, duration => 0, y => $y);
      if (${*$self}{debug}) { print "DEBUG dtext='$dtext' dur='$dur' spc='$spc'\n"; }
    }
        sleep(1);
        $self->command('quit');

#    return ($rc);
  }
  $dtext = substr($text,- $dlength,$dlength);
  $self->_text(text => $dtext, duration => $pause, y => $y) unless ($rc =~ /^CK/);
        sleep(1);
        $self->command('quit');
#  return($rc);
    }


}
