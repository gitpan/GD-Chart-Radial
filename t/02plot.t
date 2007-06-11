#!/usr/bin/perl -w
use strict;

use Test::More  tests => 32;
use GD::Chart::Radial;
use IO::File;

my $chart;
my @data = ([qw/A B C D E F G/],[12,21,23,30,23,22,5],[10,20,21,24,28,15,9]);
my @lots = ([qw/A B C D E F G/],[12,21,23,30,23,22,5],[10,20,21,24,28,15,9],[1,5,7,8,9,4,2],[15,14,10,3,20,18,16]);
my $max = 31;

my %files = (
    'test-default.png' => { 'MSWin32' => 'avn6NJBWE6VrNcdu1Kh8OQ', 'linux' => 'ooeembNOgWC71anI70XC4Q' },
	'test-Circle.jpg'  => { 'MSWin32' => 'EFBBiWEUdhxwdx3N36667g', 'linux' => 'EFBBiWEUdhxwdx3N36667g' },
	'test-Fill.jpg'    => { 'MSWin32' => 'QbczH2rII2t/seO7zpw8gw', 'linux' => 'QbczH2rII2t/seO7zpw8gw' },
	'test-Polygon.jpg' => { 'MSWin32' => '42wgk5uanXjcPov88CyPnw', 'linux' => '42wgk5uanXjcPov88CyPnw' },
	'test-Notch.jpg'   => { 'MSWin32' => '3gDHeBiCldPUj6JxtID17A', 'linux' => '3gDHeBiCldPUj6JxtID17A' },
);


# clean up
unlink $_    for(keys %files);

for my $style (qw(Fill Notch Circle Polygon)) {
#    diag("Style: $style");
    $chart = GD::Chart::Radial->new(500,500);
    isa_ok($chart,'GD::Chart::Radial','specified new');

    eval { $chart->set() };
    ok(!$@,'no errors on empty set');
    diag($@)    if(@_);

    eval { $chart->plot() };
    ok(!$@,'no errors on empty plot');
    diag($@)    if(@_);

    eval {
        $chart->set(
            legend            => [qw/april may/],
            title             => 'Some simple graph',
            y_max_value       => $max,
            y_tick_number     => 5,
            style             => $style,
            colours           => [qw/white light_grey red blue green/]
           );
    };
    ok(!$@,'no errors with set values');
    diag($@)    if(@_);

    eval { $chart->plot(\@data) };
    ok(!$@,'no errors with plot values');
    diag($@)    if(@_);

    SKIP: {
        my $file = "test-$style.jpg";
        my $fh;
        skip "Write access disabled for test files",1
            unless($fh = IO::File->new($file,'w'));

        binmode $fh;
        print $fh $chart->jpg;
        $fh->close;
        ok(-f $file,'file exists');
    }
}

{
    $chart = GD::Chart::Radial->new();
    isa_ok($chart,'GD::Chart::Radial','default new');

    eval { $chart->plot(\@lots) };
    ok(!$@,'no errors with plot values without any set');
    diag($@)    if(@_);

    SKIP: {
        my $file = 'test-default.png';
        my $fh;
        skip "Write access disabled for test files",1
            unless($fh = IO::File->new($file,'w'));

        binmode $fh;
        print $fh $chart->png;
        $fh->close;
        ok(-f $file,'file exists');
    }
}

SKIP: {
    skip "Unable to validate files for this OS", 5  
        if($^O ne 'MSWin32' && $^O ne 'linux');

    eval "use Digest::MD5";
    skip "Need Digest::MD5 to verify checksums of images", 5    if($@);

    for my $file (keys %files) {
    	my $md5 = Digest::MD5->new();

        if(my $fh = IO::File->new($file,'r')) {
        	$md5->addfile($fh);
	        $fh->close;
        	is($md5->b64digest,$files{$file}->{$^O},'MD5 passed for '.$file);
        } else {
            ok(0,'failed to open file: '.$file);
        }
    }
}

# clean up
unlink $_    for(keys %files);
