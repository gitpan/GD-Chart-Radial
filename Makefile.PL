use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'GD::Chart::Radial',
    VERSION_FROM      => 'lib/GD/Chart/Radial.pm', # finds $VERSION
    PREREQ_PM         => { GD => 2 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (AUTHOR         => 'aaron trevena <teejay@droogs.org>') : ()),
);
