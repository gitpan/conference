#	Rich's Hyper Text tools that get used in every daggone
#  Web perl script one ever writes.
#  Richard Bowen
#  Begun 12/4/95
#
#
#	Contents:
#   header - prints content type header for HTML
#   title - Prints title for html page.  Usage - &title('Desired title');
#   form_parse - parses form, sticks it into $FORM{'variable_name'}
#   footer - prints generic end of html page
#   date - returns todays date in nicer format
#   julean - returns julean date with jan 1, 1995 as day 1
#   todayjulean - returns today's julean date.  Calls julean
#
#


#  Header:  Prints html header to browser, telling it that
#  This is a html document, even though it really is not.
#
sub header
{
print "content-type: text/html \n\n";
}

#  Title:  Prints generic top of html document - nothing fancy 
#  yet, just <html><head><title>Parameter</title></head><body>.

sub title  {
	$parameter = $_[0];
	print "\n<html><head><title>$parameter</title></head><body> \n\n";
	   }

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


#	Date - returns the date and time, hopefully

sub date	{
	$date=localtime(time);
	($day, $month, $no, $hr, $year) = split (/\s+/,$date);
	$return_date = "$hr, $month $no";
	if ($month =~ /jan/i) {$month=1}     
	elsif ($month =~ /feb/i) {$month=2}  
	elsif ($month =~ /mar/i) {$month=3}  
	elsif ($month =~ /apr/i) {$month=4}  
	elsif ($month =~ /may/i) {$month=5}  
	elsif ($month =~ /jun/i) {$month=6}  
	elsif ($month =~ /jul/i) {$month=7}  
	elsif ($month =~ /aug/i) {$month=8}  
	elsif ($month =~ /sep/i) {$month=9}  
	elsif ($month =~ /oct/i) {$month=10} 
	elsif ($month =~ /nov/i) {$month=11} 
	elsif ($month =~ /dec/i) {$month=12} 
		}

sub todayjulean	{

	&date;
	&julean ($month,$day,$year);
	$today = $jule;
		}

sub julean{ 
#
# Julean date based on Jan. 1, 1992 being day 1.
# Takes date in Month, day, and year order and finds julean date.
# Outputs julean number for inputted date.
#
#	This sub written by David Moose Pitts and modified by Rich Bowen
#
#	Usage:   &julean(month, day, year);

$thisdayjulean=0;

@months=(0,31,28,31,30,31,30,31,31,30,31,30,31);

$local_month=$_[0];
$tday=$_[1];
$tyear=$_[2];
$leapdays=((($tyear-1992)/4)+1);     #must be a leap year, so I chose 1992 

# This section drops the remainder of the leap day for the year.
$leapdays2=(($tyear-1992)%4);
$leapdays-=($leapdays2*0.25);
if ($tyear>=2000) {$leapdays-= 1};   #even 100 year years do not have
                                                # leap days in them
$local_thisyear=$tyear-1992;
for ($local_i=1;$local_i<=$local_thisyear;$local_i++) {
                $thisdayjulean+=365;}
for ($local_i=1;$local_i<$local_month;$local_i++) {    #minus 1 because current month not complete
        $thisdayjulean+=@months[$local_i]}
if ($local_month<3 && $leapdays2==0) {$leapdays--};
$thisdayjulean+=$leapdays+$tday;
$jule=$thisdayjulean;
}

sub footer {print "</body></html>";}

sub redirect {
$loc=$_[0];
print"Location: $_ \n\n"; }

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
                }

1;    #  Return true
