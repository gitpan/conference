#!/usr/bin/perl
use lib '/home/rbowen/public_html/scripts/conference/';
use Conference;
use Time::JulianDay;
use strict 'vars';

my ($today, $reservation, @reservations, $Data, @new);

$today = local_julian_day(time) - $old;

open (DATA, "$datafile");
@reservations=<DATA>;
close DATA;
chomp @reservations;

for $reservation (@reservations)	{
	$Data = SplitReservation($reservation);
	push (@new,$reservation) unless $Data->{day} < $today;
}   # End for reservation

open (NEWDATA, ">$datafile");
for $reservation (@new)	{
	print NEWDATA "$reservation\n";
}  #  End for
close NEWDATA;