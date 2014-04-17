# RokuLCD.pm version 0.2
#
# sub-version of RokuUI Copyright Michael Polymenakos 2007 mpoly@panix.com
#
# Released under the GPL. http://www.gnu.org/licenses/gpl.txt
#
# Created by Ed Outhwaite to make the M400's 16x2 display easier to write to.
#

package RokuUI::RokuLCD;

require RokuUI;

@ISA = qw(RokuUI);


sub new {
  my $class = shift;
  my $self = {@_};
  bless ($self, $class);
  $self->{display_length} = 16;   # Assumed 400
  $self->{display_length} = 40 if ($self{model} == 500);
  return $self;
}


sub marquee() {
  my $self  = shift;
  return 0 if !($self->{connection});

  my %args = @_;
  my $text = $args{'text'} || "";
  my $clear    =  $args{'clear'}    || 0;
  my $keygrab  =  $args{'keygrab'};
  if ($keygrab !~ /[0..2]/) { # 0 is a valid value
    $keygrab = 1;
  }
  my $duration;
  # if ($self->{display_length} == 16) {  # bad form to directly reference an objects variable...
    $duration = (int(((length($text))+24)/25))*5;
  # }
  # else {
  #   $duration = (int(((length($text))+48)/49))*5;
  # }

#  print length($text), " $duration\n"; # use for debugging

  my ($rc) = $self->msg(text => "$text",   keygrab  => $keygrab,
                        mode => 'marquee', duration => $duration);
  return ($rc);
} # end marquee


sub teletype() { # print a large block of text
  my $self = shift;
  return 0 if !($self->{connection});
  my %args = @_;
  my $text = $args{'text'} || "";
  my $pause = $args{'pause'} || 2;
  my $linepause = $args{'linepause'} || 1;
  my $keygrab  =  $args{'keygrab'};
  if ($keygrab !~ /[0..2]/) { # 0 is a valid value
    $keygrab = 1;
  }

  # Clear display first
  $self->msg(clear=> 1, duration => 0, keygrab => $keygrab, y => 0, text => ' ');
  $self->msg(clear=> 1, duration => 0, keygrab => $keygrab, y => 1, text => ' ');

  my (@string);
  my ($line_length,$length, $y) = 0;
  my ($y0_string, $y1_string) = undef;

  my (@paras) = split(/\n/,$text);
  foreach (@paras) {
    @string = split(/ /);

    for ($ary_inx=0;$ary_inx<=$#string;$ary_inx++) {
      # This bit doesn't work... yet:
      # if (length($string[$ary_inx]) > $self->{display_length}) { # hyphenate it
      #   if (($line_length) && (($line_length + length($string[$ary_inx]) - 2) < ($self->{display_length} * 2))) {
      #     $strlen = $self->{display_length} - ($line_length+2);
      #   }
      #   else {
      #     $strlen = $self->{display_length} - 1; # second half may be bigger than display, but...
      #   }
      #   $a = substr($string[$ary_inx],0,$strlen);
      #   $b = substr($string[$ary_inx],$strlen,(length($string[$ary_inx])-$strlen));
      #   $string[$ary_inx] = "$a-$b";
      # }
      # print "$string[$ary_inx]\n";
      
      if ((length($string[$ary_inx]) + $line_length) < $self->{display_length}) {
        if ($y == 0) {
          $y0_string .= ' ' if ($y0_string);
          $y0_string .= $string[$ary_inx];
          $line_length+=(length($string[$ary_inx]));
          $line_length++;
        }
        else # we'll assume it's line 1
        {
          $y1_string .= ' ' if ($y1_string);
          $y1_string .= $string[$ary_inx];
          $line_length+=(length($string[$ary_inx]));
          $line_length++;
        }
      }
      elsif (($string[$ary_inx] =~ /^(\S+\W)(\S+)$/) && ((length($1) + $line_length + 1) < $self->{display_length})) { # split on non-word character, we're adding one because there's a space
        if ($y == 0) {
          $y0_string .= ' ' if ($y0_string);
          $y0_string .= $1;
          $rc = $self->ticker(text => $y0_string, y=>0, keygrab => $keygrab, pause=>0);
          $y = 1;
          $y1_string = $2;
          $line_length=length($2);
        }
        else {
          $y1_string .= ' ' if ($y1_string);
          $y1_string .= $1;
          $rc = $self->msg(clear => 1, text => $y0_string, duration => 0, keygrab => $keygrab, y => 0);
          $rc = $self->msg(text => $self->_spacefill(text => ' '), duration => 0, keygrab => $keygrab, y => 1);
          $rc = $self->ticker(text => $y1_string, y => 1, keygrab => $keygrab, pause => 0);
          $y0_string = substr($y1_string, (- $self->{display_length}), $self->{display_length});  # only display what was on 2nd line
          $y1_string = $2;
          $line_length=length($2);
        }
      }
      else {  # too big for line
        if ($y == 0) {
          $rc = $self->ticker(text => $y0_string, y => 0, keygrab => $keygrab, pause => 0);
          $y = 1;
          $y1_string = $string[$ary_inx];
          $line_length=(length($string[$ary_inx]));
        }
        else {
          $rc = $self->msg(text => $self->_spacefill(text => $y0_string), duration => 0, keygrab => $keygrab, y => 0);
          $rc = $self->msg(text => $self->_spacefill(text => ' '), duration => 0, keygrab => $keygrab, y => 1);
          $rc = $self->ticker(text => $y1_string, y => 1, keygrab => $keygrab, pause => 0);
          $y0_string = substr($y1_string, (- $self->{display_length}), $self->{display_length});  # only display what was on 2nd line
          $y1_string = $string[$ary_inx];
          $line_length=(length($string[$ary_inx]));
        }
      }
    }
    unless (($rc =~ /^CK/) &&  ($keygrab < 2)) {
      if ($y1_string) {
        $rc = $self->msg(text => $self->_spacefill(text => $y0_string), duration => 0, keygrab => $keygrab, y => 0);
        $rc = $self->msg(text => $self->_spacefill(text => ' '), duration => 0, keygrab => $keygrab, y => 1);
        $rc = $self->ticker(text => $y1_string, duration => $linepause, keygrab => $keygrab, y => 1);
      }
      else {
        for ($i=length($y0_string);$i<=16;$i++) { $y0_string .= ' '; }
        $rc = $self->msg(text => $y0_string, duration => 0, keygrab => $keygrab, y => 0);
        $rc = $self->msg(text => $self->_spacefill(text => ' '), duration => $linepause, keygrab => $keygrab, y => 1);
      }
    }
    $y = 1;
    $y0_string = substr($y1_string, (- $self->{display_length}), $self->{display_length}); # only display what was on 2nd line
    $y1_string = undef;
    $line_length=0;
  }
  unless (($rc =~ /^CK/) &&  ($keygrab < 2)) {
    if ($y1_string) {
      $rc = $self->msg(text => $y0_string, duration => 0, keygrab => $keygrab, y => 0);
      $rc = $self->msg(text => $self->_spacefill(text => ' '), duration => 0, keygrab => $keygrab, y => 1);
      $rc = $self->msg(text => $y1_string, duration => $linepause, keygrab => $keygrab, y => 1);
    }
    else {
      $rc = $self->msg(clear => 1, text => $y0_string, duration => $linepause, keygrab => $keygrab, y => 0);
    }
  }
} # end teletype


sub _spacefill() { # pad line with spaces - this is an internal function, and likely to change
  my $self = shift;
  return 0 if !($self->{connection});
  my %args    = @_;
  my $text    = $args{'text'}  || "";
  for ($i=length($text);$i<=$self->{display_length};$i++) {
    $text .= ' '; }
  return $text;
} # end _spacefill


sub ticker() { # an alternative to marquee
  my $self = shift;
  return 0 if !($self->{connection});
  my %args    = @_;
  my $text    = $args{'text'}  || "";
  my $pause   = $args{'pause'} || 1;
  my $y       = $args{'y'}     || 0;
  my $keygrab = $args{'keygrab'};
  if ($keygrab !~ /[0..2]/) { # 0 is a valid value
    $keygrab = 1;
  }

  my ($dtext,$dur,$offset,$spc,$tlength) = 0;
#  $self->msg(clear=>1, y=>$y, text => "                ", pause => 0);
  for ($length=1;$length<(length($text));$length++) {
    $spc++;
    $tlength++ unless ($tlength == $self->{display_length});
    $offset++ if (length($dtext) == $self->{display_length});
    $dtext = substr($text,$offset,$tlength);
    $spc = 0 if (substr($dtext,-1,1) eq ' ');
    if ((length($text) > $self->{display_length}) && (++$dur == $self->{display_length})) {
      $rc = $self->msg(text => $dtext, duration => 1, keygrab => $keygrab, y => $y);
      # print "$dtext $dur $spc\n";
      $dur = $spc;
      $dur = 0 if ($dur > $self->{display_length});
    }
    else {
      $rc = $self->msg(text => $dtext, duration => 0, keygrab => $keygrab, y => $y);
      # print "$dtext $dur $spc\n";
    }
    return ($rc) if (($rc =~ /^CK/) &&  ($keygrab < 2));
  }
  $dtext = substr($text,- $self->{display_length},$self->{display_length});
  $self->msg(text => $dtext, duration => $pause, keygrab => $keygrab, y => $y) unless (($rc =~ /^CK/) &&  ($keygrab < 2));
} # end ticker

;1;



# end of module, documentation below


__END__

=head1 NAME

RokuUI::RokuLCD - M400 & M500 Display Functions made more accessible than via the RokuUI module


=head1 SYNOPSIS


 use RokuUI::RokuLCD;
 my $display = RokuUI::RokuLCD->new(host => $rokuIP, port => 4444, model => 400);
 $display->open || die("Could not connect to Roku Soundbridge");

 my($rv) = $display->marquee(text => "This allows easy access to the marquee function - timings for M400 only");

 $display->ticker(text => "An alternative to the marquee function that can cope with large quantities of text", pause => 5);

 open (INFILE, "a_text_file.txt");
 @slurp_file = <INFILE>;
 close(INFILE);

 $display->teletype(text => "@slurp_file", pause => 2, linepause => 1);

 $display->close;

=head1 DESCRIPTION

RokuUI::RokuLCD was written because the standard RokuUI module appeared a bit too high level,
so I put together some simplified display routines into a single easy-to-use object.  It inherits
all the methods from the standard RokuUI module.

=head1 METHODS

=head2 new(host => I<host_address> [, port => I<port>] [, model => I<400 or 500>])

If not given, RokuLCD assumes that the port number is 4444, and that the model is an M400.
Be warned this will mean less than half the display being used on an M500!


=head2 marquee(text => I<text to display> [, clear => I<0/1>] [, keygrab => I<0/1/2>])

This allows quick access to the standard sketch marquee function - timings are for text sized to
the M400 display as I do not have access to an M500.

If 1 is passed to clear, it forces the display to clear first (default 0)

=head2 ticker(text => I<text to display> [, y => I<0/1>] [, pause => I<seconds>] [, keygrab => I<0/1/2>])

An alternative to the marquee that can be displayed on either the top or bottom line.


=head2 teletype(text => I<text to display> [, pause => I<seconds>] [, [linepause =>  I<seconds>] [, keygrab => I<0/1/2>])

An alternative to using marquee to display large quantities of text, scrolling the display upwards rather than from 
the right.

The length of time to pause after each line of text is given by I<linepause>, wheras I<pause> holds the
length of time to pause at the end of the text.


=head1 STANDARD VARIABLES

=head2 keygrab

determines what happens when a message is received from the remote control:

=over 4

=item * 0 (default) the routine is interrupted, and the keypress is passed on to the roku

=item * 1 the routine is interrupted, and the keypress is returned to the caller

=item * 2 the routine is not interrupted, and the keypress is discarded

=back


=head2 clear

=over 4

=item * 0 (default) do not clear display first

=item * 1 clear display first

=back


=head1 THANKS

Both ticker and teletype were inspired by Rod Lord's work on the Hitch-Hiker's Guide to the Galaxy TV program.
http://www.rodlord.com/pages/hhgg.htm


=head1 TERMS AND CONDITIONS

Copyright (c) 2008 by Ed Outhwaite.  Released under the GPL. http://www.gnu.org/licenses/gpl.txt

RokuUI is Copyright Michael Polymenakos 2007 mpoly@panix.com


=head1 AUTHOR

Ed Outhwaite
F<edstertech@googlemail.com>


=head1 VERSION

=over

=item Version 0.01 May 6, 2008 First attempt

=item Version 0.1  May 12, 2008 Deemed acceptable for initial release

=item Version 0.2  June 3, 2008 Ironed out some niggles with ticker, and finally have a script to release with the module

=back

=cut

