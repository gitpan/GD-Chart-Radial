#!/usr/bin/perl -w
use strict;

use Test::More  tests => 35;
use GD::Chart::Radial;
use IO::File;

my $chart;
my @data = ([qw/A B C D E F G/],[12,21,23,30,23,22,5],[10,20,21,24,28,15,9]);
my @lots = ([qw/A B C D E F G/],[12,21,23,30,23,22,5],[10,20,21,24,28,15,9],[1,5,7,8,9,4,2],[15,14,10,3,20,18,16]);
my $max = 31;

my %files;
while(<DATA>) {
    next    if(/^\s*$/ || /^__/);
    chomp;
    my ($file,$os,$md5) = split(',');
    $files{$file}{$os} = $md5;
}

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
        my $file = "test-$style.gd";
        my $fh;
        skip "Write access disabled for test files",1
            unless($fh = IO::File->new($file,'w'));

        binmode $fh;
        print $fh $chart->gd;
        $fh->close;
        ok(-f $file,"file [$file] exists");
    }
}

{
    $chart = GD::Chart::Radial->new();
    isa_ok($chart,'GD::Chart::Radial','default new');

    eval { $chart->plot(\@lots) };
    ok(!$@,'no errors with plot values without any set');
    diag($@)    if(@_);

    for my $type (qw(png gif jpg gd)) {
        SKIP: {
            my $file = 'test-default.'.$type;
            my $fh;
            skip "Write access disabled for test files",1
                unless($fh = IO::File->new($file,'w'));

            binmode $fh;
            print $fh $chart->$type;
            $fh->close;
            ok(-f $file,"file [$file] exists");
        }
    }
}

SKIP: {
    eval "use Digest::MD5";
    skip "Need Digest::MD5 to verify checksums of images", 5    if($@);
    my $diag;

    for my $file (keys %files) {
        SKIP: {
            skip 'Write access disabled for test files',1   unless(-f $file);
            skip 'JEPG support required in GD::Image',1         if(-z $file);

            if(my $fh = IO::File->new($file,'r')) {
                my $md5 = Digest::MD5->new();
                $md5->addfile($fh);
                $fh->close;
                if($files{$file}->{$^O}) {
                    is($md5->b64digest,$files{$file}->{$^O},'MD5 passed for '.$file);
                } else {
                    $diag .= "\n$file,$^O,".($md5->b64digest);
                    ok(1,'unable to verify file: '.$file);
                }
            } else {
                ok(0,'failed to open file: '.$file);
            }
        }
    }

    if($diag) {
        diag("\n\nTo help improve GD::Chart::Radial please forward the diagnostics below");
        diag("to me, Barbie <barbie\@missbarbell.co.uk>. Thanks in advance.");
        diag("$diag");
    }
}

# clean up
unlink $_    for(keys %files);
unlink $_    for(qw(test-default.png test-default.gif test-default.jpg));

__END__
__DATA__
test-default.gd,MSWin32,TR+ytg9Gs528UZ4lIU/OSQ
test-Circle.gd,MSWin32,VZkTQFaVddiICJkbbw9CCA
test-Fill.gd,MSWin32,Zh6BjY+dlgcJwcmK0cKLpg
test-Polygon.gd,MSWin32,MJgiRc+P5FrKDnDvtc1g2g
test-Notch.gd,MSWin32,3Ik8LPT79i7cpfwxodLObg
test-Notch.gd,linux,3Ik8LPT79i7cpfwxodLObg
test-Polygon.gd,linux,MJgiRc+P5FrKDnDvtc1g2g
test-Fill.gd,linux,Zh6BjY+dlgcJwcmK0cKLpg
test-Circle.gd,linux,VZkTQFaVddiICJkbbw9CCA
