#!/usr/bin/perl
#
#	Get rid of the old reservations
#	This goes with Rich Bowen's conference.pl Conference Room
#	Reservaton script.
#	This script needs httools.pl
########################################
require '/usr/local/etc/httpd/cgi-bin/httools.pl';
$data="reservations";	# Location of the data file
$old=3;		# Age at which to expire reservations
&todayjulean;	# Determine today's "julean" date

open (DATA, "$data");
@reservations=<DATA>;
close DATA;

for $reservation (@reservations)	{
($ID,$title,$start,$end,$name,$room,$descrip,$mon,$mday,$year)=split(/~~/,$reservation);
 #print "month=$mon, day=$mday, year=$year\n";
&julean($mon,$mday,$year);
$diff=($today-$jule);
 #print "today=$today.  jule=$jule, diff=$diff\n";
push (@new,$reservation) unless ($diff > $old);
		};   # End for reservation

open (NEWDATA, ">$data");
for $reserve (@new)	{
print NEWDATA $reserve}
close NEWDATA;
