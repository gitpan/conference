package Conference;

require Exporter;
@ISA = Exporter;
@EXPORT = qw(@Rooms
			 @Times
			 $datafile
			 $script
			 $base_url
			 $idfile
			 $templates
			 $old

		     SplitReservation
			 GetId
			);

use vars qw($VERSION);

#  A list of the available conference rooms
@Rooms=("Engineering conference room",
		"Marketing conference room",
		"Boardroom",
		"Upstairs conference room",
		"Demo neT.120 server");

#  A list of valid times.  Put "am" and "pm" in here if you want
#  them to be displayed. 
@Times=("7:00","7:30","8:00","8:30","9:00",
		"9:30","10:00","10:30","11:00","11:30",
		"Noon","12:30","1:00","1:30","2:00",
		"2:30","3:00","3:30","4:00","4:30",
		"5:00","5:30","6:00");

#  Locations and names of files
$datafile="reservations";
$idfile = "reserve_id";
$script="conference.cgi";
$base_url="/scripts/conference";

#  location of template files
$templates = "/home/rbowen/public_html/scripts/conference/templates";

$old=3;  #  How old should reservations be before we delete them?

$VERSION="3.00";

######################################

sub SplitReservation	{
	my ($reservation) = @_;
	my %Data = ();
	chomp $reservation;

	($Data{id}, $Data{title}, $Data{start},
	$Data{end}, $Data{name}, $Data{email},
	$Data{room}, $Data{description}, $Data{day})
	= split /~~/, $reservation;

	return \%Data;
}  #  End sub SplitReservation

sub GetId	{
	my ($file) = @_;
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

	return $id;
}  #  End sub GetId


1;