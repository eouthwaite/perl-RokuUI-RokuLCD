package RokuUI::RokuLCD;

use 5.006;
use strict;
use warnings;

require RokuUI;

our @ISA = qw(RokuUI);

our $VERSION = '0.03';

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

=cut

sub new {
  my $class = shift;
  my $self = {@_};
  bless ($self, $class);
  if ($self->{model} == 500) {
  	$self->{display_length} = 40;
  }
  else {
  	# Assume model == 400
  	$self->{display_length} = 16;
  }
  return $self;
}

=head2 marquee(text => I<text to display> [, clear => I<0/1>] [, keygrab => I<0/1/2>])

This allows quick access to the standard sketch marquee function - timings are for text sized to
the M400 display as I do not have access to an M500.

If 1 is passed to clear, it forces the display to clear first (default 0)

=cut

sub marquee {
  my ($self, %args)  = @_;
  if (! $self->{connection}) { return 0; };

  my $text     =  $args{'text'}  || "";
  my $clear    =  $args{'clear'} || 0;
  my $keygrab  =  $args{'keygrab'};
  if ($keygrab !~ /[0..2]/) { # 0 is a valid value
    $keygrab = 1;
  }
  my $duration = (int(((length($text))+24)/25))*5;

  if ($self->{debug}) { print "DEBUG text length = ", length($text), " duration = $duration\n"; }

  my ($rc) = $self->msg(text => "$text",   keygrab  => $keygrab,
                        mode => 'marquee', duration => $duration);
  return ($rc);
} # end marquee


sub _spacefill {
  # pad line with spaces - used to overwrite previous lines
  # WARNING! This is an internal function, and likely to change
  my $self = shift;
  return 0 if !($self->{connection});
  my %args    = @_;
  my $text    = $args{'text'}  || "";
  for (my $i=length($text);$i<=$self->{display_length};$i++) {
    $text .= ' '; }
  return $text;
} # end _spacefill



=head2 ticker(text => I<text to display> [, y => I<0/1>] [, pause => I<seconds>] [, keygrab => I<0/1/2>])

An alternative to the marquee that can be displayed on either the top or bottom line.

=cut

sub ticker { # an alternative to marquee
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

  my $rc;
  my ($dtext,$dur,$offset,$spc,$tlength) = 0;
  for (my $length=1;$length<(length($text));$length++) {
    $spc++;
    $tlength++ unless ($tlength == $self->{display_length});
    $offset++ if (length($dtext) == $self->{display_length});
    $dtext = substr($text,$offset,$tlength);
    $spc = 0 if (substr($dtext,-1,1) eq ' ');
    if ((length($text) > $self->{display_length}) && (++$dur == $self->{display_length})) {
      $rc = $self->msg(text => $dtext, duration => 1, keygrab => $keygrab, y => $y);
	  if ($self->{debug}) { print "DEBUG dtext='$dtext' dur='$dur' spc='$spc'\n"; }
      $dur = $spc;
      $dur = 0 if ($dur > $self->{display_length});
    }
    else {
      $rc = $self->msg(text => $dtext, duration => 0, keygrab => $keygrab, y => $y);
	  if ($self->{debug}) { print "DEBUG dtext='$dtext' dur='$dur' spc='$spc'\n"; }
    }
    return ($rc) if (($rc =~ /^CK/) &&  ($keygrab < 2));
  }
  $dtext = substr($text,- $self->{display_length},$self->{display_length});
  $self->msg(text => $dtext, duration => $pause, keygrab => $keygrab, y => $y) unless (($rc =~ /^CK/) &&  ($keygrab < 2));
  return($rc);
} # end ticker


=head2 teletype(text => I<text to display> [, pause => I<seconds>] [, [linepause =>  I<seconds>] [, keygrab => I<0/1/2>])

An alternative to using marquee to display large quantities of text, scrolling the display upwards rather than from 
the right.

The length of time to pause after each line of text is given by I<linepause>, wheras I<pause> holds the
length of time to pause at the end of the text.

=cut

sub teletype {
  my $self = shift;
  if (! $self->{connection}) { return 0; };
  my %args      = @_;
  my $text      = $args{'text'}      || ""; # default text is blank
  my $pause     = $args{'pause'}     || 2;  # length of time to wait in seconds before next line
  my $linepause = $args{'linepause'} || 1;  # length of additional time to wait in seconds after message 
  my $keygrab   = $args{'keygrab'};
  if ($keygrab !~ /[0..2]/) { # 0 is a valid value
    $keygrab = 1;
  }

  # Clear display first
  $self->msg(clear=> 1, duration => 0, keygrab => $keygrab, y => 0, text => ' ');
  $self->msg(clear=> 1, duration => 0, keygrab => $keygrab, y => 1, text => ' ');

  my (@string);
  my $rc;
  my ($line_length,$length, $y) = 0;
  my ($y0_string, $y1_string) = undef;

  my (@paras) = split(/\n/,$text);
  foreach (@paras) {
    @string = split(/ /);

    for (my $ary_inx=0;$ary_inx<=$#string;$ary_inx++) {
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
        for (my $i=length($y0_string);$i<=16;$i++) { $y0_string .= ' '; }
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
  return($rc);
} # end teletype

;1;

# end of module, additional documentation below

__END__

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

=head1 AUTHOR

Outhwaite, Ed, C<< <edstertech at googlemail.com> >>


=head1 VERSION

=over

=item Version 0.01  May 12, 2008 Deemed acceptable for initial release

=item Version 0.02  June 3, 2008 Ironed out some niggles with ticker, and finally have a script to release with the module

=item Version 0.03  March 15, 2014 Finally got around to CPAN style packaging

=back


=head1 ACKNOWLEDGEMENTS

Both ticker and teletype were inspired by Rod Lord's work on the Hitch-Hiker's Guide to the Galaxy TV program.
http://www.rodlord.com/pages/hhgg.htm


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Outhwaite, Ed.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

RokuUI is Copyright Michael Polymenakos 2007 mpoly@panix.com


=cut

