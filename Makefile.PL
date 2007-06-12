use ExtUtils::MakeMaker;
WriteMakefile(
    NAME            => 'GD::Chart::Radial',
    VERSION_FROM    => 'lib/GD/Chart/Radial.pm',

    PREREQ_PM       => { GD => 2 },
    NO_META         => 1,
    
    ($] >= 5.005 ?
      (AUTHOR       => 'Barbie <barbie@missbarbell.co.uk>') : ()),
);
