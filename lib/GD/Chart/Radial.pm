#####################################################################
# Radial - A module to generate radial charts as JPG and PNG images #
# (c) Copyright 2002,2004-2007 Aaron J  Trevena                     #
#####################################################################
package GD::Chart::Radial;

use strict;
use warnings;
use Data::Dumper;
use GD;

our $VERSION = 0.02;

=head1 NAME

GD::Chart::Radial - plot and output Radial or Radar charts using the GD library.

=head1 SYNOPSIS

  use GD::Chart::Radial;

  my $chart = GD::Chart::Radial->new($width, $height);
  $chart->set(title=>"This is a chart");
  $chart->plot(\@data);
  print OUTFILE $chart->png;

=head1 DESCRIPTION

This module allows you to plot and output Radial or Radar charts
using the GD library. The module is based on GD::Graph in how it
can be used where possible.

A radial chart has multiple axis spread out from the centre, like
spokes on a wheel. Each axis represents a particular measurement.
Values are plotted by marking the value for what is being measured
on each axis and optionally joining these points. The result can
look like a spiderweb or a radar depending on you plot the
values.

=head1 METHODS

=head2 new

This constructor method creates a new chart object.

  my $chart = GD::Chart::Radial->new($width,$height);

=cut

sub new {
  my ($class, $width, $height, $debug) = (@_,0);

  # instantiate Chart
  my $chart = {};
  bless($chart, ref($class) || $class);

  # initialise Chart
  $chart->{width}  = $width;
  $chart->{height} = $height;
  $chart->{debug}  = $debug;
  $chart->{PI}     = 4 * atan2 1, 1;
  return $chart;
}

=head2 set

This accessor sets attributes of the graph such as the Title

  $chart->set(title=>"This is a chart");

or

  $chart->set(
        legend            => [qw/april may/],
        title             => 'Some simple graph',
        y_max_value       => $max,
        y_tick_number     => 5,
        style             => 'Notch',
        colours           => [qw/light_grey red blue green/]
       );

Style can be Notch, Circle, Polygon or Fill. The default style is Notch. Where
style is set to Fill, the data sets are also filled, as opposed to lines drawn
for all other styles

Colours can be any of the following: white, black, red, blue, purple, green, 
grey, light_grey, dark_grey, cream, yellow, orange. The first colour in the
list is used exclusively for the scale markings. For the remaining colours, if
there are less colours than data sets, the additional data sets will reuse 
colours from the list. The default list of colours are light_grey, red, blue 
and green.

Note that if you only specify one colour, then that colour will be used for
the scale markings and the data sets will use the default list of colours.

=cut

sub set {
  my $self = shift;
  my %attributes = @_;
  foreach my $attribute (%attributes) {
    next unless ($attributes{$attribute});
    $self->{$attribute} = $attributes{$attribute};
  }
}

=head2 plot

This method plots the chart based on the data provided and the attributes of the graph

  my @data = ([qw/A B C D E F G/],
              [12,21,23,30,23,22,5],
              [10,20,21,24,28,15,9]);
  $chart->plot(\@data);

=cut

sub plot {
  my $self = shift;
  my @values = @{shift()};
  my @labels = @{shift(@values)};
  my @records;
  my $r = 0;
  my $Colour  = $self->{colours} ? shift @{$self->{colours}} : 'light_grey';
  my @colours = $self->{colours} ? @{$self->{colours}} : qw/red blue green yellow orange/;

  my $Max = 0;
  foreach my $values (@values) {
    my $record;
    $record = { Label => $self->{legend}->[$r], Colour => $colours[$r] };
    my $v = 0;
    foreach my $value (@$values) {
      $record->{Values}->{$labels[$v]} = $value;
      $Max = $value if($Max < $value);
      $v++;
    }
    push(@records,$record);
    $r++;
  }

  $self->{records} = \@records;

  my $PI = $self->{PI};
  my $title = $self->{title};

  # style can be Fill, Circle, Polygon or Notch
  my %scale = (
           Max       => $self->{y_max_value}    || $Max,
           Divisions => $self->{y_tick_number}  || $Max,
           Style     => $self->{style}          || "Fill",
           Colour    => $Colour
          );

  my (@axis, %axis_lookup);
  my $longest_axis_label = 0;
  my $a = 0;
  foreach my $key (@labels) {
    push (@axis, { Label => "$key" });
    $axis_lookup{$key} = $a;
    $longest_axis_label = length $key
      if (length $key > $longest_axis_label);
    $a++;
  }

  my $number_of_axis = scalar @axis;
  my $legend_height  = 8 + (15 * scalar @{$self->{records}});

  my $left_space    = 15 + $longest_axis_label * 6;
  my $right_space   = 15 + $longest_axis_label * 6;
  my $top_space     = 50;
  my $bottom_space  = 30 + $legend_height;

  my $min_radius    = 100;
  my $max_width     = $self->{width}  || $min_radius;
  my $max_height    = $self->{height} || $min_radius;
  $max_width        = $min_radius   if($max_width  < $min_radius);
  $max_height       = $min_radius   if($max_height < $min_radius);

  my $x_centre  = $left_space + $max_width;
  my $y_centre  = $top_space + $max_height;
  my $height    = (2 * $max_height) + $bottom_space + $top_space;
  my $width     = (2 * $max_width) + $left_space + $right_space;

  $self->{_im} = new GD::Image($width,$height);

  my %colours = (
         white      => $self->{_im}->colorAllocate(255,255,255),
         black      => $self->{_im}->colorAllocate(0,0,0),
         red        => $self->{_im}->colorAllocate(255,0,0),
         blue       => $self->{_im}->colorAllocate(0,0,255),
         purple     => $self->{_im}->colorAllocate(230,0,230),
         green      => $self->{_im}->colorAllocate(0,255,0),
         grey       => $self->{_im}->colorAllocate(128,128,128),
         light_grey => $self->{_im}->colorAllocate(170,170,170),
         dark_grey  => $self->{_im}->colorAllocate(75,75,75),
         cream      => $self->{_im}->colorAllocate(200,200,240),
         yellow     => $self->{_im}->colorAllocate(255,255,0),
         orange     => $self->{_im}->colorAllocate(255,128,0),
        );

  $self->{colours} = \%colours;

  my @shape_subs = (
            \&draw_triangle,
            \&draw_circle,
            \&draw_square,
            \&draw_diamond,
           );

  my $Theta = 90;
  my $i=$number_of_axis;
  foreach my $axis (@axis) {
    my $proportion;
    my $theta;
    my $x;
    my $y;

    if ($i > 0) {
      $proportion = $i / $number_of_axis;
      $theta = ((360 * $proportion) + $Theta) % 360;
      $axis->{theta} = $theta;
      $theta *= ((2 * $PI) / 360);
    } else {
      $axis->{theta} = $Theta;
      $theta = $Theta;
    }
    $x = cos $theta - (2 * $theta);
    $y = sin $theta - (2 * $theta);

    my $x_outer = ($x * 100) + $x_centre;
    my $x_proportion =  ($x >= 0) ? $x : $x - (2 * $x) ;
    my $x_label = ($x_outer >= $x_centre) 
                    ? $x_outer + 3 
                    : $x_outer - ((length ( $axis->{Label} ) * 5) + (3 * $x_proportion));
    my $y_outer = ($y * 100) + $y_centre;
    my $y_proportion =  ($y >= 0) ? $y : $y - (2 * $y) ;
    my $y_label = ($y_outer >= $y_centre) 
                    ? $y_outer + (3 * $y_proportion) 
                    : $y_outer - (9 * $y_proportion);

    $axis->{X} = $x;
    $axis->{Y} = $y;

    # round down coords
    $x_outer =~ s/(\d+)\..*/$1/;
    $y_outer =~ s/(\d+)\..*/$1/;
    $x_label =~ s/(\d+)\..*/$1/;
    $y_label =~ s/(\d+)\..*/$1/;

    # draw axis
    $self->{_im}->line($x_outer,$y_outer,$x_centre,$y_centre,$colours{black});
    # add label for axis
    $self->{_im}->string(gdTinyFont,$x_label, $y_label, $axis->{Label}, $colours{dark_grey});      
    $i--;
  }

  # loop through adding scale, and values
  my @Numbers;

  $r = 0;
  $i = 0;
  foreach my $axis (@axis) {
    my $x = $axis->{X};
    my $y = $axis->{Y};
    # draw scale
    my $theta1;
    my $theta2;
    if ($scale{Style} eq "Notch")  {
      $theta1 = $axis->{theta} + 90;
      $theta2 = $axis->{theta} - 90;
      # convert theta to radians
      $theta1 *= ((2 * $PI) / 360);
      $theta2 *= ((2 * $PI) / 360);
      for (my $j = 0 ; $j <= $scale{Max} ; $j+= int($scale{Max} / $scale{Divisions})) {
        next if ($j == 0);
        my $x_interval = $x_centre + ($x * (100 / $scale{Max}) * $j);
        my $y_interval = $y_centre + ($y * (100 / $scale{Max}) * $j);
        my $x1 = cos $theta1 - (2 * $theta1);
        my $y1 = sin $theta1 - (2 * $theta1);
        my $x2 = cos $theta2 - (2 * $theta2);
        my $y2 = sin $theta2 - (2 * $theta2);
        my $x1_outer = ($x1 * 3 * ($j / $scale{Max})) + $x_interval;
        my $y1_outer = ($y1 * 3 * ($j / $scale{Max})) + $y_interval;
        my $x2_outer = ($x2 * 3 * ($j / $scale{Max})) + $x_interval;
        my $y2_outer = ($y2 * 3 * ($j / $scale{Max})) + $y_interval;

        $self->{_im}->line($x1_outer,$y1_outer,$x_interval,$y_interval,$colours{$scale{Colour}});
        $self->{_im}->line($x2_outer,$y2_outer,$x_interval,$y_interval,$colours{$scale{Colour}});

        # Add Numbers to scale
        if ($i == 0) {
            push @Numbers, [$x_interval + 2,$y_interval - 11,$j,$colours{$scale{Colour}}];
        }
      }
    }

    if ($scale{Style} eq "Polygon" || $scale{Style} eq "Fill")  {
      for (my $j = 0 ; $j <= $scale{Max} ; $j+=($scale{Max} / $scale{Divisions})) {
        next if ($j == 0);
        my $x_interval_1 = $x_centre + ($x * (100 / $scale{Max}) * $j);
        my $y_interval_1= $y_centre + ($y * (100 / $scale{Max}) * $j);
        my $x_interval_2 = $x_centre + ($axis[$i-1]->{X} * (100 / $scale{Max}) * $j);
        my $y_interval_2= $y_centre + ($axis[$i-1]->{Y} * (100 / $scale{Max}) * $j);

        # Add Numbers to scale
        if ($i == 0) {
          push @Numbers, [$x_interval_1 + 2,$y_interval_1 - 11,$j,$colours{$scale{Colour}}];
        } else {
          $self->{_im}->line($x_interval_1,$y_interval_1,$x_interval_2,$y_interval_2,$colours{$scale{Colour}});
          if ($i == $number_of_axis -1) {
            my $x_interval_2 = $x_centre + ($axis[0]->{X} * (100 / $scale{Max}) * $j);
            my $y_interval_2= $y_centre + ($axis[0]->{Y} * (100 / $scale{Max}) * $j);
            $self->{_im}->line($x_interval_1,$y_interval_1,$x_interval_2,$y_interval_2,$colours{$scale{Colour}});
          }
        }
      }
    }

    if ($scale{Style} eq "Circle")  {
      for (my $j = 0 ; $j <= $scale{Max} ; $j+=($scale{Max} / $scale{Divisions})) {
        if ($i == 0) {
          my $x_interval = $x_centre + ($x * (100 / $scale{Max}) * $j);
          my $y_interval = $y_centre + ($y * (100 / $scale{Max}) * $j);
          next if ($j == 0);
          push @Numbers, [$x_interval + 2,$y_interval - 11,$j,$colours{$scale{Colour}}];
        } else {
          my $radius = (200 / $scale{Max}) * $j;
          $self->{_im}->arc($x_centre,$y_centre,$radius,$radius,$axis->{theta}-2,$axis[$i-1]->{theta}-2,$colours{$scale{Colour}});
          $self->{_im}->arc($x_centre,$y_centre,$radius,$radius,$axis->{theta}+2,$axis[0]->{theta}-2,$colours{$scale{Colour}}) if ($i == $number_of_axis);
        }
      }
    }

    # draw value
    if ($i != 0) {
      my $r = 0;
      foreach my $record (@{$self->{records}}) {
        my $value = $record->{Values}->{$axis->{Label}};
        my $colour = $colours{$record->{Colour}};
        my $x_interval_1 = $x_centre + ($x * (100 / $scale{Max}) * $value);
        my $y_interval_1 = $y_centre + ($y * (100 / $scale{Max}) * $value);

        if ($scale{Style} eq "Fill")  {
          push @{$record->{Points}}, [$x_interval_1,$y_interval_1];
          if ($i == $number_of_axis -1) {
            my $first_value  = $record->{Values}->{$axis[0]->{Label}};
            my $x_interval_2 = $x_centre + ($axis[0]->{X} * (100 / $scale{Max}) * $first_value);
            my $y_interval_2 = $y_centre + ($axis[0]->{Y} * (100 / $scale{Max}) * $first_value);
            push @{$record->{Points}}, [$x_interval_2,$y_interval_2];
          }
        } else {
          $self->draw_shape($x_interval_1,$y_interval_1,$record->{Colour}, $r);

          my $last_value = $record->{Values}->{$axis[$i-1]->{Label}};
          my $x_interval_2 = $x_centre + ($axis[$i-1]->{X} * (100 / $scale{Max}) * $last_value);
          my $y_interval_2 = $y_centre + ($axis[$i-1]->{Y} * (100 / $scale{Max}) * $last_value);
          $self->{_im}->line($x_interval_1,$y_interval_1,$x_interval_2,$y_interval_2,$colour);

          if ($i == $number_of_axis -1) {
            my $first_value  = $record->{Values}->{$axis[0]->{Label}};
            my $x_interval_2 = $x_centre + ($axis[0]->{X} * (100 / $scale{Max}) * $first_value);
            my $y_interval_2 = $y_centre + ($axis[0]->{Y} * (100 / $scale{Max}) * $first_value);
            $self->{_im}->line($x_interval_1,$y_interval_1,$x_interval_2,$y_interval_2,$colour);
            $self->draw_shape($x_interval_2,$y_interval_2,$record->{Colour}, $r);
          }
          $r++;
        }
      }
    }
    $i++;
  }

  # Fill is a filled polgon
  if ($scale{Style} eq "Fill")  {
    foreach my $record (@{$self->{records}}) {
      my $poly = GD::Polygon->new();
      $poly->addPt($_->[0],$_->[1]) for(@{$record->{Points}});
      $self->{_im}->filledPolygon($poly,$colours{$record->{Colour}});
    }
  }

  # draw scale values
  pop @Numbers; # take off the outer value as it conflicts with the label
  $self->{_im}->string(gdTinyFont,@{$_})    for(@Numbers);

  # draw Legend
  my $longest_legend = 0;
  foreach my $record (@{$self->{records}}) { 
    $longest_legend = length $record->{Label} 
      if ( $record->{Label} && length $record->{Label} > $longest_legend );
  }
  my ($legendX, $legendY) = (
                   ($width / 2) - (6 * (length "Legend") / 2),
                   ($height - ($legend_height + 10))
                  );
  $self->{_im}->string(gdSmallFont,$legendX,$legendY,"Legend",$colours{dark_grey});
  my $legendX2 = $legendX - (($longest_legend * 5) + 2);
  $legendY += 15;
  $r = 0;

  foreach my $record (@{$self->{records}}) {
    my $colour = $record->{Colour};
    $self->{_im}->string(gdTinyFont,$legendX2,$legendY,$record->{Label},$colours{$colour})  if($record->{Label});
    $self->{_im}->line($legendX+10,$legendY+4,$legendX + 35,$legendY+4,$colours{$colour});
    $self->draw_shape($legendX+22,$legendY+4,$record->{Colour}, $r);
    $legendY += 15;
    $r++;
  }

  # draw title
  if($title) {
      my ($titleX, $titleY) = ( ($width / 2) - (6 * (length $title) / 2),20);
      $self->{_im}->string(gdSmallFont,$titleX,$titleY,$title,$colours{dark_grey});
  }
  return 1;
}

=head2 png

returns a PNG image for output to a file or wherever.

  open(IMG, '>test.jpg') or die $!;
  binmode IMG;
  print IMG $chart->png;
  close IMG

=cut

sub png {
  my $self = shift;
  return $self->{_im}->png();
}

=head2 jpg

returns a JPEG image for output to a file or elsewhere, see png.

=cut

sub jpg {
  my $self = shift;
  return $self->{_im}->jpeg(95);
}

##########################################################

=head2 Internal Methods

In order to draw the points on the chart, the following 5 shape drawing 
functions are used:

=over 4

=item draw_shape

=item draw_diamond

=item draw_square

=item draw_circle

=item draw_triangle

=item draw_cross

=back

However, the latter is not supported yet.

=cut

sub draw_shape {
    my ($self,$x,$y,$colour,$i) = @_;
    my $shape;
    if (exists $self->{records}->[$i]->{Shape} ) {
        $shape = $self->{records}->[$i]->{Shape};
    } else {
        $shape = ($i > 3) ? int ($i / ($i / 4))  : $i ;
        $self->{records}->[$i]->{Shape} = $shape;
    }
    if ($shape == 0) {
        $self->draw_diamond($x,$y,$colour);
        return 1;
    }
    if ($shape == 1) {
        $self->draw_square($x,$y,$colour);
        return 1;
    }
    if ($shape == 2) {
        $self->draw_circle($x,$y,$colour);
        return 1;
    }
    if ($shape == 3) {
        $self->draw_triangle($x,$y,$colour);
        return 1;
    }
}

sub draw_diamond {
    my ($self,$x,$y,$colour) = @_;
    $x-=3;
    my $poly = new GD::Polygon;
    $poly->addPt($x,$y);
    $poly->addPt($x+3,$y-3);
    $poly->addPt($x+6,$y);
    $poly->addPt($x+3,$y+3);
    $poly->addPt($x,$y);
    $self->{_im}->filledPolygon($poly,$self->{colours}->{$colour});
    return 1;
}

sub draw_square {
    my ($self,$x,$y,$colour) = @_;
    $x-=3;
    $y-=3;
    my $poly = new GD::Polygon;
    $poly->addPt($x,$y);
    $poly->addPt($x+6,$y);
    $poly->addPt($x+6,$y+6);
    $poly->addPt($x,$y+6);
    $poly->addPt($x,$y);
    $self->{_im}->filledPolygon($poly,$self->{colours}->{$colour});
    return 1;
}

sub draw_circle {
    my ($self,$x,$y,$colour) = @_;
    $self->{_im}->arc($x,$y,7,7,0,360,$self->{colours}->{$colour});
    $self->{_im}->fillToBorder($x,$y,$self->{colours}->{$colour},$self->{colours}->{$colour});
    return 1;
}

sub draw_triangle {
    my ($self,$x,$y,$colour) = @_;
    $x-=3;
    $y+=3;
    my $poly = new GD::Polygon;
    $poly->addPt($x,$y);
    $poly->addPt($x+3,$y-6);
    $poly->addPt($x+6,$y);
    $poly->addPt($x,$y);
    $self->{_im}->filledPolygon($poly,$self->{colours}->{$colour});
    return 1;
}

sub draw_cross {
    warn "not drawing crosses yet!\n";
    return 1;
}


1;
__END__

=head1 SEE ALSO

L<GD>,
L<GD::Graph>,
L<Imager::Chart::Radial>

=head1 AUTHOR

  Current Maintainer: Barbie <barbie@missbarbell.co.uk>
  Original Author: Aaron J Trevena <aaron@droogs.org>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2002,2004-2007 Aaron Trevena
  Copyright (C) 2007 Barbie

  This module is free software; you can redistribute it or modify it
  under the same terms as Perl itself.

=cut

