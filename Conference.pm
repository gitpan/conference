package Conference;

require Exporter;
@ISA = Exporter;
@EXPORT = qw(@Rooms @Times $datafile $idfile $set_cookies
			 $user $admin $base_url $templates $old

		     SplitReservation Cookies GetId FormParse 
		     PrintTemplate PrintHeader Switch
			);

use vars qw($VERSION);

#  A list of the available conference rooms
@Rooms = ("Engineering conference room",
		"Marketing conference room",
		"Boardroom",
		"Upstairs conference room",
		);

#  A list of valid times.  Put "am" and "pm" in here if you want
#  them to be displayed. 
@Times=("7:00","7:30","8:00","8:30","9:00",
		"9:30","10:00","10:30","11:00","11:30",
		"Noon","12:30","1:00","1:30","2:00",
		"2:30","3:00","3:30","4:00","4:30",
		"5:00","5:30","6:00");

#  Locations and names of files
$datafile  = 'reservations';
$idfile    = 'reserve_id';
$user      = 'conference.cgi';
$admin     = 'admin.cgi';
$base_url  = '/scripts/conference';

#  location of template files
$templates = '/home/rbowen/public_html/scripts/conference/templates';

#  How old should reservations be before we delete them?
$old       = 3;

#  Do you want to set cookies?
$set_cookies = 1;

$VERSION='3.10.003';

######################################

sub SplitReservation	{
	my ($reservation) = @_;
	my %Data = ();
	chomp $reservation;

	@Data{'id', 'title', 'start', 'end', 'name',
	      'email', 'room', 'description', 'day'}
	= split /~~/, $reservation;

	return \%Data;
}  #  End sub SplitReservation

sub GetId	{
	my ($file) = @_;
	my $lockfile = $file . ".lock";

	#  Get a lock on the lock file
	open (LOCK, ">$lockfile");
	flock LOCK, 2;

	# Get an id number
	open (ID, $file);
	my $id=<ID>;
	close ID;
	$id++;
	if ($id >= 1000000)	{
		$id=1;
	}
	open (ID, ">$idfile");
	print ID $id;
	close ID;

	#  Release the lock
	flock LOCK, 8;
	close LOCK;

	return $id;
}  #  End sub GetId

sub FormParse  {
#  Parse HTML form, POST or GET.  Returns pointer to hash of name,value
	my ($buffer,@pairs,$pair,$name,$value,$form);

	if ($ENV{REQUEST_METHOD} eq "POST")	{
		read (STDIN, $buffer, $ENV{'CONTENT_LENGTH'});
	}  else  {
		$buffer = $ENV{QUERY_STRING};
	}

	# Split the name-value pairs
	@pairs = split(/&/, $buffer);

	foreach $pair (@pairs)
	{
    	($name, $value) = split(/=/, $pair);
    	$value =~ tr/+/ /;
    	$value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
    	$value =~ s/~!/ ~!/g;

		if ($form->{$name})	{
			$form->{$name} .= "\0$value"
		} else {
	    	$form->{$name} = $value;
		}
	}     # End of foreach

	return $form;
}	#  End of sub

sub PrintTemplate	{
#  Displays an HTML template file in canonical RCBowen format,
#  substituting values from %details.
	my ($template,$basedir);
	local $_;

	($basedir,$template, $_) = @_;
	my %details = %$_;

	open (TEMPLATE, "$basedir/$template.html");
	for $line (<TEMPLATE>)	{
		$line =~ s/%%%(.*?)%%%/$details{$1}/g;
		print $line;
	}  #  End for
	close TEMPLATE;
} #  End sub PrintTemplate

sub PrintHeader	{
	print "Content-type: text/html\n\n";
}

sub Switch      {
#  Determine which routine is to be called
        my ($action,$actions,$default) = @_;
        my @Actions = @$actions;

        if (grep /^$action$/, @Actions) {
                return $action;
        }  else  {
                return $default;
        }
} # End sub Switch

sub Cookies	{
    if (defined $ENV{HTTP_COOKIE})  {
          my $Cookie;
          my @cookies = split /;\s*/, $ENV{HTTP_COOKIE};
          for (@cookies)  {
               /(.*)=(.*)/;
               $Cookie->{$1} = $2;
          }
		  return $Cookie 
     }  else  {
		  return undef;
	 } #  End if..else
} #  End sub Cookies

1;