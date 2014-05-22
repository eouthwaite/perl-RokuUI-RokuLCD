package Roku::LCD;

use v5.10.1;
use strict;
use warnings;
use Time::HiRes qw(sleep);
use Readonly;

# Constants
Readonly::Scalar our $EMPTY       => q{};
Readonly::Scalar our $SPACE       => q{ };
Readonly::Scalar our $M400        => 400;  # Model type
Readonly::Scalar our $M500        => 500;  # Model type
Readonly::Scalar our $M400WIDTH   => 16;   # M400 screen width
Readonly::Scalar our $M500WIDTH   => 40;   # M500 screen width
Readonly::Scalar our $LETTERPAUSE => 0.25; # Time to pause between printing characters

require Roku::RCP;

use parent qw(Roku::RCP);

our $VERSION = '0.04';

=head1 NAME

Roku::LCD - M400 & M500 Display Functions made more accessible than via the Roku::RCP module

=head1 VERSION

=over

=item Version 0.04  May 24, 2014 - moved namespace ; refactored main methods 

=back

=head1 SYNOPSIS


 use Roku::LCD;
 my $display = Roku::LCD->new($rokuIP);
 if (! display) { die("Could not connect to Roku Soundbridge"); }
 
 my($rv) = $display->marquee(text => "This allows easy access to the marquee function - timings for M400 only");

 $display->ticker(text => "An alternative to the marquee function that can cope with large quantities of text", pause => 5);

 open (INFILE, "a_text_file.txt");
 @slurp_file = <INFILE>;
 close(INFILE);

 $display->teletype(text => "@slurp_file", pause => 2, linepause => 1);

 $display->Quit;

=head1 DESCRIPTION

Roku::LCD was written because the RokuUI module appeared a bit too high level, so I put together some simplified display
routines into a single easy-to-use object.

It has now been moved to using the Roku::RCP module which is easily available from CPAN.

It inherits all the methods from the standard Roku::RCP module.

=head1 METHODS

=head2 new(host => I<host_address> [, port => I<port>] [, model => I<400 or 500>])

If not given, the port number is assumed to be 4444, and the model will be determined from the displaytype
command (if that fails, the model type will be set to M400).

=cut

sub new {
    my $self = shift;
    my $class = ref($self) || $self;
    my ( $host, %args );
    $host = shift if ( scalar(@_) % 2 );
    %args = @_;
    $args{Host} = $host if $host;

    if (! $args{Host}) { return; }

    $self = $class->SUPER::new( $host, Port => $args{Port} || '4444' );

    if (! defined $self)  { return; }

    if ( $args{model} ) {
	    if ( $args{model} == $M500 ) {
	        ${*$self}{display_length} = $M500WIDTH ;
            ${*$self}{model} = $args{model};
	    }
	    elsif ( $args{model} == $M400 ) {
	        ${*$self}{display_length} = $M400WIDTH ;
            ${*$self}{model} = $args{model};
	    }
	    else {
	    	print 'WARNING: unrecognised model type, ', $args{model}, " trying display type\n";
	    }
    }

    if (! ${*$self}{model} ) {
	    $self->command("displaytype");
	    # M400 returns "16x2 LCD" - I assume M500 returns "40x2 LCD"
	
	    my @responses = $self->sb_response();
	    foreach my $response (@responses) {
	
		    print "displaytype = '$response' ?\n";
		    if ($response =~ /^(\d{2})x/) {
		        ${*$self}{display_length} = $1;
		        if (${*$self}{display_length} == $M500WIDTH) {
		        	${*$self}{model} = $M500 ;
		        }
		        else {
		            ${*$self}{model} = $M400 ;
		        }
		        last;
		    }
	    }
	    
	    if (! ${*$self}{model}) {
            print "WARNING: unrecognised display type - unknown model type.  Setting to 16x2.\n";
	        ${*$self}{display_length} = $M400WIDTH ;
	        ${*$self}{model} = $M400;
	    }
	
	    if ( ${*$self}{debug} ) {
            print "DEBUG display length = ${*$self}{display_length}; model = ${*$self}{model} = 400\n";
	    }
    }

    return bless $self, $class;
}    # end new

=head2 marquee(text => I<text to display> [, clear => I<0/1>])

This allows quick access to the standard sketch marquee function - timings are for text sized to
the M400 display as I do not have access to an M500.

If 1 is passed to clear, it forces the display to clear first (default 0)

=cut

sub marquee {
    my ( $self, %args ) = @_;

    # only take over if on standby
    if (! $self->onstandby ) {
        return ("Soundbridge running");
    }
    my $text  = $args{'text'}  || $EMPTY;
    my $clear = $args{'clear'} || 0;

    # duration is a magic number - time to wait before releasing display.
    my $duration = ( int( ( ( length($text) ) + 24 ) / 25 ) ) * 5;

    if ( ${*$self}{debug} ) {
        print "DEBUG text length = ", length($text),
          " duration = $duration\n";
    }

    if ($clear) { $self->_clear; }
    $self->command("sketch -c marquee -start \"$text\"");
    sleep($duration);
    $self->command('sketch -c quit');
    $self->command('sketch -c exit');

    return ($self->sb_response);
}    # end marquee


sub _clear {
	# clear the display
    my $self = shift;
    $self->command('sketch -c clear');
    my $rc = $self->sb_response;
    return ($rc);
}

sub _spacefill {
    # pad line with spaces - used to overwrite previous lines
    # WARNING! This is an internal function, and likely to change
    my ( $self, %args ) = @_;
    my $text = $args{'text'} || $EMPTY;
    my $tl   = length($text);

    # how many spaces do we need ?
    my $spc = ${*$self}{display_length} - $tl;
    if ($spc < 1) {
    	# no padding required
    	return $text;
    }
    else {
        my $pattern = "%${tl}s%${spc}s";
        return sprintf $pattern, $text, $SPACE;
    }
}    # end _spacefill

sub _text {
# internal function allowing easy access to the sketch "text" command
# usage:
#   _text(text => I<text to display> , duration => I<length of time to display> [, clear => I<0/1>], x => I<c/0-screen width>, y => I<0/1>)
    my ( $self, %args ) = @_;

    my $text  = $args{'text'}  || $SPACE;
    my $x     = $args{'x'}     || 0;
    my $y     = $args{'y'}     || 0;
    my $duration = $args{'duration'};

    $self->command("text $x $y \"$text\"");
    sleep($duration);
    return 1;
}    # end _text

=head2 ticker(text => I<text to display> [, y => I<0/1>] [, pause => I<seconds>])

An alternative to the marquee that can be displayed on either the top or bottom line.

=cut

sub ticker {    # an alternative to marquee
    my ( $self, %args ) = @_;
    # only take over if on standby
    if (! $self->onstandby ) {
        return ('Soundbridge running');
    }
    
    $self->command('sketch');

    $self->_ticker(%args);

    $self->command('quit');
    my $rc = $self->sb_response;
    return ($rc);
} # end ticker


sub _ticker {    # the real function - also used by teletype
    my ( $self, %args ) = @_;
    my $text  = $args{'text'}  || $EMPTY;
    my $pause = $args{'pause'} || 5;
    my $y     = $args{'y'}     || 0;
    my $dlength = ${*$self}{display_length};
    my $offset  = 0;   # offset for taking a substring
    my $dtext   = '0'; # currently displayed text
    my $tlength = 0;   # length of currently displayed text
    my $dur     = 0;
    my $spc     = 0;

    my $length = 0;
    while(++$length < ( length($text) ) ) {
        $spc++;
        if ( $tlength != $dlength ) {
        	# current text length != display width
        	$tlength++;
        }

        if ( length($dtext) == $dlength ) { 
        	# increase the offset if the displayed text is the same length as the screen width
        	$offset++;
        }

        $dtext = substr( $text, $offset, $tlength );
        $spc = 0 if ( substr( $dtext, -1, 1 ) eq ' ' );

        if ( ( length($text) > $dlength ) && ( ++$dur == $dlength ) ) {
            # print "length > dlength && dur == dlength\n";
            $self->_text( text => $dtext, duration => $LETTERPAUSE, y => $y );
            if ( ${*$self}{debug} ) {
                print "DEBUG dtext='$dtext' dur='$dur' spc='$spc'\n";
            }
            $dur = $spc;
            $dur = 0 if ( $dur > $dlength );
        }
        else {
            # print "length <= dlength || dur != dlength\n";
            $self->_text( text => $dtext, duration => $LETTERPAUSE, y => $y );
            if ( ${*$self}{debug} ) {
                print "DEBUG dtext='$dtext' dur='$dur' spc='$spc'\n";
            }
        }
    }
    $dtext = substr( $text, -$dlength, $dlength );
    $self->_text( text => $dtext, duration => $pause, y => $y );
    return 1;
}    # end _ticker

=head2 teletype(text => I<text to display> [, pause => I<seconds>] [, [linepause =>  I<seconds>])

An alternative to using marquee to display large quantities of text, scrolling the display upwards rather than from 
the right.

The length of time to pause after each line of text is given by I<linepause>, wheras I<pause> holds the
length of time to pause at the end of the text.

=cut

sub teletype {
    my ( $self, %args ) = @_;
    my $text      = $args{'text'}      || $EMPTY; # default text is blank
    my $linepause = $args{'linepause'} || 1;      # length of time to wait in seconds before next line
    my $pause     = $args{'pause'}     || 1;      # length of additional time to wait in seconds after message

    # only take over if on standby
    if (! $self->onstandby ) {
    	return ("Soundbridge running");
    }

    $self->command('sketch'); # put the command session into sketch mode

    # Clear display first
    $self->_clear;

    my @string;
    my $rc;                                      # message returned by method
    my $dlength     = ${*$self}{display_length}; # width of display
    my $line_length = 0;                         # current length of line
    my $y           = 0;                         # start at the top
    my $y0_string   = undef;                     # used to build the top string
    my $y1_string   = undef;                     # used to build the bottom string

    my (@paras) = split( /\n/, $text );  # break the text into paragraphs
    foreach (@paras) {
        @string = split(/ /);            # break the paragraph into words (split on space)

        # work through each word in the array (ary_inx holds the current word's position)
        for ( my $ary_inx = 0 ; $ary_inx <= $#string ; $ary_inx++ ) {

            if ( ( length( $string[$ary_inx] ) + $line_length ) <
                $dlength )
                # if the word will fit on the current line
                # (note less than as a space needs to be accomodated too)
            {
                if ( $y == 0 ) {
                    $y0_string .= ' ' if ($y0_string);
                    $y0_string .= $string[$ary_inx];
                    $line_length += ( length( $string[$ary_inx] ) );
                    $line_length++;
                }
                else    # we'll assume it's line 1
                {
                    $y1_string .= ' ' if ($y1_string);
                    $y1_string .= $string[$ary_inx];
                    $line_length += ( length( $string[$ary_inx] ) );
                    $line_length++;
                }
            }
            # elsif the word will not fit on the current line but contains a non-word character - split on that (add one to the length because there's a space)
            elsif ( ( $string[$ary_inx] =~ /^(\S+\W)(\S+)$/ )
                && ( ( length($1) + $line_length + 1 ) <
                    $dlength ) )
            {
                if ( $y == 0 ) {
                    $y0_string .= ' ' if ($y0_string);
                    $y0_string .= $1;
                    $rc = $self->_ticker(
                        text    => $y0_string,
                        y       => 0,
                        pause   => $LETTERPAUSE
                    );
                    $y           = 1;
                    $y1_string   = $2;
                    $line_length = length($2);
                }
                else {
                    $y1_string .= ' ' if ($y1_string);
                    $y1_string .= $1;
                    $rc = $self->_text(
                        text     => $y0_string,
                        duration => 0,
                        y        => 0
                    );
                    $rc = $self->_text(
                        text     => $self->_spacefill( text => ' ' ),
                        duration => 0,
                        y        => 1
                    );
                    $rc = $self->_ticker(
                        text    => $y1_string,
                        y       => 1,
                        pause   => $LETTERPAUSE
                    );
                    $y0_string = substr(
                        $y1_string,
                        ( -$dlength ),
                        $dlength
                    );    # only display what was on 2nd line
                    $y1_string   = $2;
                    $line_length = length($2);
                }
            }
            else {        # too big for line
                if ( $y == 0 ) {
                    $rc = $self->_ticker(
                        text    => $y0_string,
                        y       => 0,
                        pause   => $LETTERPAUSE
                    );
                    $y           = 1;
                    $y1_string   = $string[$ary_inx];
                    $line_length = ( length( $string[$ary_inx] ) );
                }
                else {
                    $rc = $self->_text(
                        text     => $self->_spacefill( text => $y0_string ),
                        duration => 0,
                        y        => 0
                    );
                    $rc = $self->_text(
                        text     => $self->_spacefill( text => ' ' ),
                        duration => 0,
                        y        => 1
                    );
                    $rc = $self->_ticker(
                        text    => $y1_string,
                        y       => 1,
                        pause   => $LETTERPAUSE
                    );
                    $y0_string = substr(
                        $y1_string,
                        ( -$dlength ),
                        $dlength
                    );    # only display what was on 2nd line
                    $y1_string   = $string[$ary_inx];
                    $line_length = ( length( $string[$ary_inx] ) );
                }
            }
        }
        unless ( $rc =~ /^CK/ ) {
            if ($y1_string) {
                $rc = $self->_text(
                    text     => $self->_spacefill( text => $y0_string ),
                    duration => 0,
                    y        => 0
                );
                $rc = $self->_text(
                    text     => $self->_spacefill( text => ' ' ),
                    duration => 0,
                    y        => 1
                );
                $rc = $self->_ticker(
                    text     => $y1_string,
                    pause    => $linepause,
                    y        => 1
                );
            }
            else {
                for ( my $i = length($y0_string) ; $i <= $dlength ; $i++ ) {
                    $y0_string .= ' ';
                }
                $rc = $self->_text(
                    text     => $y0_string,
                    duration => 0,
                    y        => 0
                );
                $rc = $self->_text(
                    text     => $self->_spacefill( text => ' ' ),
                    duration => $linepause,
                    y        => 1
                );
            }
        }
        $y         = 1;
        $y0_string = substr(
            $y1_string,
            ( -$dlength ),
            $dlength
        );    # only display what was on 2nd line
        $y1_string   = undef;
        $line_length = 0;
    }
    unless ( $rc =~ /^CK/ ) {
        if ($y1_string) {
            $rc = $self->_text(
                text     => $y0_string,
                duration => 0,
                y        => 0
            );
            $rc = $self->_text(
                text     => $self->_spacefill( text => ' ' ),
                duration => 0,
                y        => 1
            );
            $rc = $self->_text(
                text     => $y1_string,
                duration => $linepause,
                y        => 1
            );
        }
        else {
            $rc = $self->_text(
                text     => $self->_spacefill( text => $y0_string ),
                duration => 0,
                y        => 0
            );
            $rc = $self->_text(
                text     => $self->_spacefill( text => ' ' ),
                duration => $linepause,
                y        => 1
            );
        }
    }
    sleep($pause);
    $self->command('quit');
    $rc = $self->sb_response;
    return ($rc);
}    # end teletype

=head2 onstandby

Checks whether the Soundbridge is on standby (returns true) or in use (returns false)

=cut

sub onstandby {

    # an almost direct lift of RokuUI's ison function
    # this is used to see whether the radio is in use
    my $self = shift;
    $self->command("ps");

    for my $ps ( $self->sb_response ) {
        return 1 if $ps =~ /StandbyApp/;
    }
    return 0;
}    # end onstandby

=head2 sb_response

Used to return any command responses; filtering out prompts

=cut

sub sb_response {

    # this is used to return any command responses, but filter out prompts
    my $self = shift;
    return map {
        if ( ( !/^SoundBridge\>/ ) && ( !/^Sketch>/ ) ) { $_; }
    } $self->response();
}    # end sb_response

1;

# end of module, additional documentation below

__END__

=head1 STANDARD VARIABLES

=head2 clear

=over 4

=item * 0 (default) do not clear display first

=item * 1 clear display first

=back


=head1 BUGS AND LIMITATIONS

=head2 To do list

=over 4

=item * teletype method requires refactoring.

=back

=head1 AUTHOR

Outhwaite, Ed, C<< <edster at gmx.com> >>


=head1 ACKNOWLEDGEMENTS

Both ticker and teletype were inspired by Rod Lord's work on the Hitch-Hiker's Guide to the Galaxy TV program.
http://www.rodlord.com/pages/hhgg.htm


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Outhwaite, Ed.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

