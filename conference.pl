#!/usr/bin/perl
#
#	Reserve a conference room
#	Rich Bowen
#	rbowen@databeam.com
#	http://www.databeam.com/
#	

#	variables
#	these should be settable to whatever you want

@rooms=("Engineering conference room","Marketing conference room","Boardroom","Upstairs conference room");
@times=("7:00","7:30","8:00","8:30","9:00","9:30","10:00","10:30","11:00","11:30","Noon","12:30","1:00","1:30","2:00","2:30","3:00","3:30","4:00","4:30","5:00","5:30","6:00");
#  once you set this, @times should forever thereafter keep the same number of elements.
$datafile="reservations";
$version="0.1";
$base_url="/cgi-bin/Internal";
@links=("/index.html~~DataBeam Homepage","/Internal/~~Internal Homepage");

print "content-type: text/html \n\n";
$num_rooms=$#rooms;
$num_times=$#times;

# Grab the arguments
$args=$ENV{'QUERY_STRING'};
($command,$other)=split(/&/,$args);

#  Determine which subroutine we are calling
if ($ENV{'PATH_INFO'}=~/goto/) {&goto}
else	{
if ($command eq "delete")	{&delete}
elsif ($command eq "delete2") {&delete2}
elsif ($command eq "details") {&details}
elsif ($command eq "edit") {&edit}
elsif ($command eq "edit2") {&edit2}
elsif ($command eq "edit3") {&edit3}
elsif ($command eq "reserve") {&reserve}
elsif ($command eq "reserve2") {&reserve2}
else	{&display};
}

sub display	{
#  Show all the appointments for "today"
$date=$other;
($mon,$mday,$year)=split(/_/,$date);

if ($date eq "")	{
($sec,$min,$hour,$mday,$mon,$year,$wday,$isdst)=localtime(time);
$year+=1900;
$mon++; }
&month_txt($mon);
&yesterday;
&tomorrow;
&weekday;


print <<ENDHTML1;
<html>
<head><title>Conference room reservations - $weekday, $month_txt $mday, $year</title>
</head>
<body bgcolor=#FFFFFF>
<h3>Conference Room Reservations - $weekday, $month_txt $mday, $year</h3>
<center>
[ <a href="$base_url/conference.pl?reserve&$mon\_$mday\_$year">Reserve a room</a> | <a href="$base_url/conference.pl?delete&$mon\_$mday\_$year">Delete a reservation</a> | <a href="$base_url/conference.pl?edit&$mon\_$mday\_$year">Edit a reservation</a> ]
</center>
<center>
<form method=get action=conference.pl/goto>
<input type=submit value="Jump"> to <input name="mon" size=2 value="$mon"> / <input name="day" size=2 value="$mday"> / <input name="year" size=4 value="$year">
</form>
[ <a href="$base_url/conference.pl?display&$y_mon\_$y_day\_$y_year">Previous day</a> | <a href="$base_url/conference.pl">Today</a> | <a href="$base_url/conference.pl?display&$t_mon\_$t_day\_$t_year">Next day</a> ]
</center>
<hr>
<table border width=100%>
ENDHTML1

open (DATAFILE, $datafile);
@reservations=<DATAFILE>;
close DATAFILE;

#  Print table headers
print "<tr>";

print "<th>Time";
for $room (@rooms)	{
print "<th>$room";	}

for ($time=0;$time<=$num_times;$time++)	{
print "<tr>\n";
print "<td align=middle>@times[$time]";
	for ($room=0;$room<=$num_rooms;$room++)  {
	print "<td align=middle>";
	#  Print reservations for that room, that hour
	for $reservation (@reservations){
# print $reservation;
	($id,$title,$start,$end,$name,$con_room,$descrip,$con_time,$con_month,$con_day,$con_year)=split(/~~/,$reservation);
	if ($time==$con_time && $room==$con_room && $mon==$con_month && $mday==$con_day && $year==$con_year)
		{print "<a href=\"$base_url/conference.pl?details&$id\">$title</a>";}  #  Endif ... phew!!
		};  #  End for reservation
				}
}

print "</table>";

#  Print some footer stuff
print "<hr>";
&toolbar;
print "</body></html>";

}	# end display


sub details	{
#  Display details on a particular conference reservation
$id_num=$other;

open (DATAFILE, $datafile);
@reservations=<DATAFILE>;
close DATAFILE;


@reservations=grep(/^$id_num~/,@reservations);

# $index=0;
# repeat {
# $index++;
# ($id,$title,$start,$end,$name,$con_room,$descrip,$con_time,$con_month,$con_day,$con_year)=split(/~~/,@reservations[$index]);
# }
 # until ($id == $id_num);
# 
($id,$title,$start,$end,$contact,$con_room,$descrip,$con_time,$con_month,$con_day,$con_year)=split(/~~/,@reservations[0]);
# I had to do that again because stuff done in the loop is lost
&month_txt($con_month);
($name,$email)=split(/&&/,$contact);
$mon=$con_month;$mday=$con_day;$year=$con_year;&weekday;

print <<ENDHTML2;
<html>
<head><title>$title</title></head>
<body bgcolor=#FFFFFF>
<h2>$title</h2>
@rooms[$con_room]<br>
@times[$start] - @times[$end]<br>
$weekday, $month_txt $con_day, $con_year<br>
<blockquote>
$descrip
</blockquote>
Contact 
ENDHTML2

#  Only link it to the email if they provided an email address.
print "<a href=\"mailto:$email\">" unless ($email eq "");
print "$name";
print "</a>" unless ($email eq "");
print " for more details.<br>";

print <<ENDFOOTER;
<hr>
<center>
[ <a href="$base_url/conference.pl?display&$con_month\_$con_day\_$con_year">Back</a> to the schedule | <a href="$base_url/conference.pl?edit&$mon\_$mday\_$year">Edit a reservation</a> ]<br>
ENDFOOTER
&toolbar;
print "</body></html>\n";
	}  # End sub details


sub reserve	{
#	Reserve a particular room
#	we will need to do cool stuff like check for conflicts!!
$date=$other;
($mon,$mday,$year)=split(/_/,$date);

print <<ENDHTML3;
<html>
<head><title>Reserve a room</title></head>
<body bgcolor=#FFFFFF>
<h3>Reserve a room</h3>
Please fill out the information below thoroughly.<br>
<hr>
<form method=post action=conference.pl?reserve2>
<b>Title of meeting</b>: 
<input size=35 name="title"><br>
This will be visible on the schedule, so make it short and descriptive (<i>customer training</i>, <i>IMTC conf. call</i>, <i>neT.120 design meeting</i>, etc)
<p>

<b>Description of the meeting</b> - You may list required materials, agenda items, etc.  You may put HTML markup in this field.<br>
<textarea name="descrip" cols=60 rows=4></textarea><br>
<p>
<b>Date</b>: (month/day/year) <input name="month" size=2 value="$mon"> / <input name="day" size=2 value="$mday"> / <input name="year" size=4 value="$year"> <br>
ENDHTML3

#  OK, now the tricky stuff ...
print "<b>Start time</b>: <select name=\"start\">";
for ($i=0;$i<=$num_times;$i++)	{
print "<option value=$i>$times[$i]\n";	}
print "</select>";

print "&nbsp\;&nbsp\;&nbsp\;\n";

print "<b>End time</b>: <select name=\"end\">";
for ($i=0;$i<=$num_times;$i++)	{
print "<option value=$i>$times[$i]\n";	}
print "</select><br>\n";

print "<b>Conference room</b>: ";
print "<select name=room>\n";
for ($i=0;$i<=$num_rooms;$i++)	{
print "<option value=$i>$rooms[$i]\n";	}
print "</select><br>\n";

print "<b>Name</b>: <input name=\"name\"><br>\n";
print "<b>Email address</b>: <input name=\"email\"><br>\n";
print "<hr>";
print "<input type=submit value=\"Make reservation\">\n";
print "</form>";
&toolbar;
print "</body></html>";
	}	# End reserve

sub reserve2	{
# This actually does the work of putting the data in the file
# Also does the verification

#get the data
&form_parse;

# Get an id number
open (ID, "reserve_id");
$id=<ID>;
close ID;

# increment the id and alter the file
$id++;if($id>9999){$id=1};
open (NEWID, ">reserve_id");
print NEWID $id;
close NEWID;
# print $id;

#  Do verification here ...
$passed="yes";
#  First, make sure that all the fields are filled in ...
for $key (keys %FORM)	{
if ($FORM{$key} eq "" && $key ne "email" && $key ne "descrip"){$error.="<li>You need to enter a value for $key.";
			$passed="no";	}}

#  Check to see that the times are reasonable
if ($FORM{'start'}>=$FORM{'end'}){$error.="<li>Your meeting ends before it starts, or is of zero length.";
	$passed="no";	}
#  Now, look for conference conflicts
open (DATAFILE, $datafile);
@reservations=<DATAFILE>;
close DATAFILE;

$conflict="no";
foreach $reservation (@reservations)	{
($conf_id,$title,$start,$end,$name,$room,$descrip,$time,$month,$day,$year)=split(/~~/,$reservation);
if ($room==$FORM{'room'} && $month==$FORM{'month'} && $day==$FORM{'day'} && $year==$FORM{'year'} && $time==$FORM{'start'}) {$conflict="yes"};	}
if ($conflict eq "yes")	{
		$error.="<li>There is a conflict with another meeting.";
		$passed="no"}

# Then, if it passed, put the stuff in the file
if ($passed eq "yes")	{

#  Take carriage returns out of the description field
$FORM{'descrip'}=~s/\n/<br>/g;
$FORM{'descrip'}=~s/\r//g;

open (DATAFILE, ">>$datafile");

for ($time=$FORM{'start'};$time<$FORM{'end'};$time++)	{
# Make reservation string
$reservation="$id~~$FORM{'title'}~~$FORM{'start'}~~$FORM{'end'}~~$FORM{'name'}&&$FORM{'email'}~~$FORM{'room'}~~$FORM{'descrip'}~~$time~~$FORM{'month'}~~$FORM{'day'}~~$FORM{'year'}";

print DATAFILE "$reservation\n";
	}	#  end for $time
close DATAFILE;

# Then print an HTML confirmation
$mday=$FORM{'day'};$mon=$FORM{'month'};$year=$FORM{'year'};
&weekday;
&month_txt($FORM{'month'});
print <<ENDHTML4;
<html>
<head><title>Reservation made</title></head>
<body bgcolor="#FFFFFF">
<h3>Reservation made</h3>
The following reservation was made:<br>
$FORM{'title'}<br>
$weekday, $month_txt $mday, $FORM{'year'}<br>
@times[$FORM{'start'}] - @times[$FORM{'end'}] in @rooms[$FORM{'room'}]<br>
<blockquote>$FORM{'descrip'}</blockquote><br>
Contact <a href="mailto:$FORM{'email'}">$FORM{'name'}</a> for more details.<br>
<hr>
<center><a href="$base_url/conference.pl?display&$mon\_$mday\_$FORM{'year'}">Schedule for $weekday, $month_txt $mday, $FORM{'year'}</a></center><br>
ENDHTML4
&toolbar;
print"</body></html>\n";
	}   #end if passed

else	{	# i.e. did not pass.
print <<ENDHTML5;
<html>
<head><title>Error!</title></head>
<body bgcolor=#FFFFFF>
<h3>Error!</h3>
There was an error, and I was unable to schedule the meeting that you wanted.<br>
The error(s) follow:<br>
<ul>
$error
</ul>
Please look at the <a href="$base_url/conference.pl">schedule</a> and try again.
</body></html>
ENDHTML5
	}

}	# End reserve2

sub delete {
# Deletes meetings - gives a list to choose from
($mon,$mday,$year)=split(/\_/,$other);
&weekday;
&month_txt($mon);

print <<ENDHTML6;
<html>
<head><title>Delete a reservation</title></head>
<body bgcolor=#FFFFFF>
<h2>Delete a reservation from $weekday, $month_txt $mday, $year</h2>
Choose from this list:<hr>
<form method=post action="$base_url/conference.pl?delete2&$mon\_$mday\_$year">
ENDHTML6

open (DATAFILE, "$datafile");
@reservations=<DATAFILE>;
close DATAFILE;

while(@reservations){
$next=@reservations[0];
push (@unique,$next);
($id,@stuff)=split(/~~/,$next);
@reservations=grep(!/^$id~/,@reservations);
	} # End while
	#  @unique should now be just one entry per meeting.

foreach $line(@unique){
($id,$title,$start,$end,$name,$con_room,$descrip,$con_time,$con_month,$con_day,$con_year)=split(/~~/,$line);
if ($mon==$con_month && $mday==$con_day && $year==$con_year){
print "<input type=checkbox name=\"$id\">";
print "$title (@times[$start] - @times[$end] in @rooms[$con_room])<br>\n";
	}   # End if
} #  End foreach

print "<hr>";
print "<input type=submit value=\"Delete\"><hr>";
&toolbar;
print "</body></html>";
} # end delete


sub delete2	{
#  Does the actual work of deleting the reservations
($mon,$mday,$year)=split(/\_/,$other);
&weekday;
&month_txt($mon);
&form_parse;

# The id(s) to be deleted will just be the keys of $FORM
# for $key(keys %FORM)	{
# print "$key<br>";}

open (DATAFILE, "$datafile");
@reservations=<DATAFILE>;
close DATAFILE;

for $key (keys %FORM)	{
@reservations=grep(!/^$key~/,@reservations);
	}

open (DATAFILE, ">$datafile");
for $line (@reservations){
print DATAFILE $line};
close DATAFILE;

print <<ENDHTML7;
<html>
<head><title>Entries deleted</title></head>
<body bgcolor=#FFFFFF>
The entries that you selected have been deleted.<hr>
<center><a href="$base_url/conference.pl?display&$mon\_$mday\_$year">Schedule for $weekday, $month_txt $mday, $year</a></center><br>
ENDHTML7
&toolbar;
print "</body></html>\n";
	}  # End delete2

sub edit{
# Pick an existing reservation and edit the details
# This will reuse a bunch of the code from the add and delete sections.

($mon,$mday,$year)=split(/\_/,$other);
&weekday;
&month_txt($mon);

print <<ENDHTML8;
<html>
<head><title>Edit an existing reservation for $weekday, $month_txt $mday, $year</title></head>
<body bgcolor=#FFFFFF>
<h2>Edit a reservation for $weekday, $month_txt $mday, $year</h2>
Choose from this list:<hr>
<form method=post action="$base_url/conference.pl?edit2">
ENDHTML8

open (DATAFILE, "$datafile");
@reservations=<DATAFILE>;
close DATAFILE;

while(@reservations){
$next=@reservations[0];
push (@unique,$next);
($id,@stuff)=split(/~~/,$next);
@reservations=grep(!/^$id~/,@reservations);
	} # End while
	#  @unique should now be just one entry per meeting.

foreach $line(@unique){
($id,$title,$start,$end,$name,$con_room,$descrip,$con_time,$con_month,$con_day,$con_year)=split(/~~/,$line);
if ($mon==$con_month && $mday==$con_day && $year==$con_year){
print "<input type=radio name=\"ID\" value=\"$id\">";
print "$title (@times[$start] - @times[$end] in @rooms[$con_room])<br>\n";
	}   # End if
} #  End foreach
print "<hr>";
print "<input type=submit value=\"Edit\"><hr>";
&toolbar;
print"</body></html>\n";
	}  # End edit

sub edit2{
#  Sets up a form with the current values of the variables
&form_parse;
$edit_id=$FORM{'ID'};

open (DATAFILE, "$datafile");
@reservations=<DATAFILE>;
close DATAFILE;

@reservations=grep(/^$edit_id~/,@reservations);
#  Get rid of all the stuff that is not the right one.

($id,$title,$start,$end,$contact,$room,$descrip,$time,$mon,$mday,$year)=split(/~~/,@reservations[0]);
($name,$email)=split(/&&/,$contact);
$descrip=~s/<br>/\n/;

print <<ENDHTML9;
<html><head><title>Edit reservation - $title</title></head>
<body bgcolor=#FFFFFF>
<h2>Edit reservation - $title</h2>
Please correct the fields below:<br>
<form method=post action=conference.pl?edit3>
<input type=hidden name="id" value="$id">
<b>Title of meeting</b>: 
<input size=35 name="title" value="$title"><br>
This will be visible on the schedule, so make it short and descriptive (<i>customer training</i>, <i>IMTC conf. call</i>, <i>neT.120 design meeting</i>, etc)<br>
<b>Description of the meeting</b> - You may list required materials, agenda items, etc.  You may put HTML markup in this field.<br>
<textarea name="descrip" cols=60 rows=4>$descrip</textarea><br>
<p>
<b>Date</b>: (month/day/year) <input name="month" size=2 value="$mon"> / <input name="day" size=2 value="$mday"> / <input name="year" size=4 value="$year"> <br>
ENDHTML9

#  OK, now the tricky stuff ...
print "<b>Start time</b>: <select name=\"start\">";
for ($i=0;$i<=$num_times;$i++)	{
print "<option value=$i";
if ($i==$start){print " selected "};
print">$times[$i]\n";	}
print "</select>";

print "&nbsp\;&nbsp\;&nbsp\;\n";

print "<b>End time</b>: <select name=\"end\">";
for ($i=0;$i<=$num_times;$i++)	{
print "<option value=$i";
if ($i==$end){print" selected "};
print">$times[$i]\n";	}
print "</select><br>\n";

print "<b>Conference room</b>: ";
print "<select name=room>\n";
for ($i=0;$i<=$num_rooms;$i++)	{
print "<option value=$i";
if ($i==$room){print" selected "};
print">$rooms[$i]\n";	}
print "</select><br>\n";

print "<b>Name</b>: <input name=\"name\" value=\"$name\"><br>\n";
print "<b>Email address</b>: <input name=\"email\" value=\"$email\"><br>\n";
print "<hr>";
print "<input type=submit value=\"Edit reservation\">\n";
print "</form>";
&toolbar;
	}	#  End edit2


sub edit3	{
&form_parse;
$id=$FORM{'id'};
print "<html><head><title>Editing a reservation - $FORM{'title'}</title>";
print "</head><body bgcolor=#FFFFFF>";
print "<h3>Editing reservation - $FORM{'title'}</h3>";
print "<hr>";
# print "<b>$id</b>";
#  Do verification here ...
$passed="yes";
#  First, make sure that all the fields are filled in ...
for $key (keys %FORM)	{
if ($FORM{$key} eq ""){$error.="<li>You need to enter a value for $key.";
			$passed="no";	} # end if
} # end for $key

#  Check to see that the times are reasonable
if ($FORM{'start'}>=$FORM{'end'}){$error.="<li>Your meeting ends before it starts, or is of zero length.";
	$passed="no";	} #  End if
#  Now, look for conference conflicts
open (DATAFILE, "$datafile");
@reservations=<DATAFILE>;
close DATAFILE;

@reservations=grep(!/^$id~/,@reservations); # Get rid of the old version

$conflict="no";
foreach $reservation (@reservations)	{
($conf_id,$title,$start,$end,$name,$room,$descrip,$time,$month,$day,$year)=split(/~~/,$reservation);
if ($room==$FORM{'room'} && $month==$FORM{'month'} && $day==$FORM{'day'} && $year==$FORM{'year'} && $time==$FORM{'start'}) {$conflict="yes"}; # end if
	}  # end foreach
if ($conflict eq "yes")	{
		$error.="<li>There is a conflict with another meeting.";
		$passed="no"}

# Then, if it passed, put the stuff in the file
if ($passed eq "yes")	{
# Put the other stuff back in
open (DATAFILE, ">$datafile");
for $line (@reservations){print DATAFILE $line}
close DATAFILE;

#  Take carriage returns out of the description field
$FORM{'descrip'}=~s/\n/<br>/g;
$FORM{'descrip'}=~s/\r//g;

open (DATAFILE, ">>$datafile");

for ($time=$FORM{'start'};$time<$FORM{'end'};$time++)	{
# Make reservation string
$reservation="$id~~$FORM{'title'}~~$FORM{'start'}~~$FORM{'end'}~~$FORM{'name'}&&$FORM{'email'}~~$FORM{'room'}~~$FORM{'descrip'}~~$time~~$FORM{'month'}~~$FORM{'day'}~~$FORM{'year'}";
print DATAFILE "$reservation\n";
	}	#  end for $time
close DATAFILE;

#  Print attractive HTML stuff
$mon=$FORM{'month'};$mday=$FORM{'day'};$year=$FORM{'year'};
&weekday;&month_txt($mon);
print <<ATTRACTIVE;
The reservation has been changed.<br>
<center><a href="$base_url/conference.pl?display&$FORM{'month'}\_$FORM{'day'}\_$FORM{'year'}">Schedule for $weekday, $month_txt $FORM{'day'}, $FORM{'year'}</a></center><br>
ATTRACTIVE

&toolbar;
print "</body></html>";
} #  End "if passed eq yes"

else { # Did not pass
print "$error<br><b>You appear to have made the above errors!!</b>\n";
} # end else
} # end edit3

sub goto        {
#
#  Go to a particular date
#  Data comes in as QUERY_STRING
# &form_parse is not used

($pair1, $pair2, $pair3)=split(/&/,$args);
($junk, $mday)=split(/=/, $pair2);
($junk, $mon)=split(/=/, $pair1);
($junk, $year)=split(/=/, $pair3);
#  Need some error checking ...
if ($mon eq ""){$mon=1};
if ($year eq ""){$year=1996};
if ($mon>12) {$mon=12};
if ($mon<1) {$mon=1};
if ($year<1) {$year=1};
if ($year>9999) {$year=9999};
$other="$mon\_$mday\_$year";
&display   }               #  End of &goto


sub yesterday	{
# determine what yesterday was, given $mon, $mday, $year
@months=(31,31,28,31,30,31,30,31,31,30,31,30,31,31);
$y_day=($mday-1);
$y_mon=$mon;
$y_year=$year;
if ($y_day==0)	{
	$y_mon--;
	$y_day=@months[$y_mon];	}
if ($y_mon==0)	{
	$y_year--;
	$y_mon=12;	}
} # End yesterday

sub tomorrow	{
# determine what tomorrow will be, given $mon, $mday, $year
@months=(31,31,28,31,30,31,30,31,31,30,31,30,31,31);
$t_day=($mday+1);
$t_mon=$mon;
$t_year=$year;
if ($t_day>@months[$t_mon])	{
	$t_mon++;
	$t_day=1;	}
if ($t_mon==13)	{
	$t_year++;
	$t_mon=1;	}
} # End tomorrow

sub weekday	{
#  Determine day of week
$y=$year;
$m=$mon;
$d=$mday;
@d = (0,3,2,5,0,3,5,1,4,6,2,4);
@day = (Sunday, Monday, Tuesday, Wednesday, Thursday, Friday, Saturday);
$y-- if $m < 3;
$weekday = $day[($y+int($y/4)-int($y/100)+int($y/400)+$d[$m-1]+$d) % 7];
}	# End weekday

sub toolbar{
print "<center>[ <a href=\"$base_url/conference.pl\">Today's Schedule</a>\n";
for $link(@links){
($link_url,$link_name)=split(/~~/,$link);
print" | <a href=\"$link_url\">$link_name</a>\n";}
print" ]</center><br>\n";
print "Please direct questions and suggestions regarding this application to <a href=\"mailto:rbowen\@databeam.com\">Rich Bowen</a>.";
} #  end toolbar

#  form_parse:  Reads in the form information from a post and
#  parses it out into $FORM{'variable_name'}
sub form_parse  {
	# Get the input 
	read (STDIN, $buffer, $ENV{'CONTENT_LENGTH'});

	# Split the name-value pairs
	@pairs = split(/&/, $buffer);

	foreach $pair (@pairs)
	{
    	($name, $value) = split(/=/, $pair);

    	# Un-Webify plus signs and %-encoding
    	$value =~ tr/+/ /;
    	$value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;

    	# Stop people from using subshells to execute commands
    	# Not a big deal when using sendmail, but very important
    	# when using UCB mail (aka mailx).
    	# $value =~ s/~!/ ~!/g;

    	# Uncomment for debugging purposes
    	# print "Setting $name to $value<P>";

    	$FORM{$name} = $value;
	}     # End of foreach
	}	#  End of sub

sub month_txt   {
($_)=@_;
if ($_==1) {$month_txt = "January"}
elsif ($_==2) {$month_txt="February"}
elsif ($_==3) {$month_txt="March"}
elsif ($_==4) {$month_txt="April"}
elsif ($_==5) {$month_txt="May"}
elsif ($_==6) {$month_txt="June"}
elsif ($_==7) {$month_txt="July"}
elsif ($_==8) {$month_txt="August"}
elsif ($_==9) {$month_txt="September"}
elsif ($_==10) {$month_txt="October"}
elsif ($_==11) {$month_txt="November"}
elsif ($_==12) {$month_txt="December"}
else {$month_txt="ERROR"};
                }  # end month_txt