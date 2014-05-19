use v5.10.1;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Roku::RokuLCD',
    AUTHOR           => q{Outhwaite, Ed <edstertech@googlemail.com>},
    VERSION_FROM     => 'lib/RokuUI/RokuLCD.pm',
    ABSTRACT_FROM    => 'lib/RokuUI/RokuLCD.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => v5.10.1,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 6.56,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Roku::RCP'   => 0,
        'Time::HiRes' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'RokuUI-RokuLCD-*' },
);
