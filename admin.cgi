#!/usr/bin/perl 
use Conference;
use Time::JulianDay;
use Time::CTime qw(:DEFAULT @MonthOfYear);
use strict 'vars';

my $form = FormParse;

my @Actions = qw(Reserve Add
				 Edit Update
				 Delete Confirm
				);

my $routine = Switch($form->{action}, \@Actions, 'Reserve');
my ($template, $details) = &{$routine}($form);

PrintHeader();
PrintTemplate($templates, $template, $details);

sub Reserve	{
	#	Reserve a particular room
	my ($form) = @_;
	my ($template, %details, $i, $todaytime, $Cookies);
	
	if ($form->{today} eq "")	{
		$form->{today} = local_julian_day(time);
	}
	$todaytime = jd_secondslocal($form->{today},0,0,0);

	for ($i=0;$i<=$#Times;$i++)	{
		$details{select_time} .= "<option value=$i>$Times[$i]\n";
	}  #  End for

	for ($i=0;$i<=$#Rooms;$i++)	{
		$details{select_room} .= "<option value=$i>$Rooms[$i]\n";
	}  #  End for

	$details{month} = strftime('%m', localtime($todaytime));
	for ($i=1; $i<=12; $i++)	{
		$details{months} .= "<option value=$i";
		if ($i == $details{month})	{
			$details{months} .= " SELECTED";
		}
		$details{months} .= ">$MonthOfYear[$i-1]\n";
	}  #  End for

	$details{year} = strftime('%Y', localtime($todaytime));
	$details{day} = strftime('%d', localtime($todaytime));
	$details{today_text} = strftime('%B %o, %Y', localtime($todaytime));
	$details{form_action} = $admin;

	$Cookies = Cookies;
	if (defined $Cookies->{name})	{
		$details{name} = $Cookies->{name};
	}
	if (defined $Cookies->{email})	{
		$details{email} = $Cookies->{email};
	}

	$template = 'reserve';
	return ($template, \%details);
}	# End reserve

sub Add	{
	#  Add reservation to the database
	my ($form) = @_;
	my ($template, %details, @reservations, $conflict,
		$id, $day, $Data, $reservation, $Cookies);

	$id = GetId($idfile);
	$day = julian_day($form->{year}, $form->{month}, $form->{day});

	#  Meeting ends before it begins?
	if ($form->{start} >= $form->{end})	{
		$details{error} .= "<li>Your meeting ends before it starts, or is of zero length.\n";
	}  #  End if

	#  Now, look for conference conflicts
	open (DATAFILE, $datafile);
	@reservations=<DATAFILE>;
	close DATAFILE;

	#  We really only need to look at today's reservations
	@reservations = grep /~$day$/, @reservations;

	$conflict="0";
	foreach $reservation (@reservations)	{
		$Data = SplitReservation($reservation);

		if ($Data->{room} == $form->{room} &&
			$form->{start} < $Data->{end} &&
			$form->{end} > $Data->{start} )	{
				$conflict = 1;
		} # End if
	} #  End foreach

	if ($conflict)	{
		$details{error} .= "<li>There is a conflict with another meeting.";
	}

	if ($details{error} eq "")	{
		#  If there were no problems, write it to the file

		#  Convert returns to HTML
		$form->{description} =~ s/\n/<br>/g;
		$form->{description} =~ s/\r//g;
		$form->{description} =~ s/<br><br>/<p>/g;

		# Make reservation string
		$reservation = join '~~', 
			$id,$form->{title},$form->{start},$form->{end},
			$form->{name},$form->{email},$form->{room},
			$form->{description},$day;

		#  Get a lock on the lock file
		my $lockfile = $datafile . ".lock";
		open (LOCK, ">$lockfile");
		flock LOCK, 2;

		#  Print data to the data file.
		open (DATAFILE, ">>$datafile");
		print DATAFILE "$reservation\n";
		close DATAFILE;

		#  Release lock
		flock LOCK, 8;
		close LOCK;

		# Then print an HTML confirmation
		%details = %$form;
		$details{day_text} = 
			strftime('%A, %B %o, %Y',
					 localtime(jd_secondslocal($day,0,0,0)));

		$details{meeting_time} = "$Times[$form->{start}] - $Times[$form->{end}]";
		$details{room_name} = "$Rooms[$form->{room}]";

		$template = 'redirect';
		$details{URL} = "$user?action=Display&today=$day";
	}	else	{ #  There were error messages
		$template = 'error';
		$details{error} .= qq~
		<p>
		There were some problems scheduling your meeting.<br>
		Please go back and try again.
		~;
	}  #  End if ... else

	if ($set_cookies)	{
		$Cookies = Cookies;
		if ($form->{name} && ($form->{name} ne $Cookies->{name})) {
			print "Set-Cookie: name=$form->{name}; expires=Monday June 1, 2034; path=$base_url\n";
		}
		if ($form->{email} && ($form->{email} ne $Cookies->{email})) {
			print "Set-Cookie: email=$form->{email}; expires=Monday June 1, 2034; path=$base_url\n";
		}
	}  #  End if $set_cookies

	return ($template, \%details);
}	# End sub Add

sub Delete {
	# Confirm that they really want to delete the meeting
	my ($form) = @_;
	my ($template, %details, @reservations, $Data);
	%details = %$form;
	
	open (DATAFILE, "$datafile");
	@reservations=<DATAFILE>;
	close DATAFILE;

	@reservations = grep /^$form->{id}~/, @reservations;
	#  Should only return one entry ...
	$Data = SplitReservation($reservations[0]);

	$details{delete_action} = $admin;
	$details{no_delete_action} = $user;
	$details{title} = $Data->{title};
	$template = 'confirm_delete';
	return ($template, \%details);
} # end sub Delete


sub Confirm	{
	#  Does the actual work of deleting the reservations
	my ($form) = @_;
	my ($template, %details, @reservations, $reservation, $Data);

	open (DATAFILE, "$datafile");
	@reservations=<DATAFILE>;
	close DATAFILE;
	chomp @reservations;

	#  Remove the matching reservation.
	($reservation) = grep /^$form->{id}~/, @reservations;
	@reservations = grep !/^$form->{id}~/, @reservations;

	#  Get a lock on the lock file
	my $lockfile = $datafile . ".lock";
	open (LOCK, ">$lockfile");
	flock LOCK, 2;
	
	#  Rewrite the datafile
	open (DATAFILE, ">$datafile");
	for (@reservations)	{
		print DATAFILE "$_\n";
	}
	close DATAFILE;

	#  Release lock
	flock LOCK, 8;
	close LOCK;
	
	$Data = SplitReservation($reservation);
	$template = 'redirect';
	$details{URL} = "$user?action=Display&today=$Data->{day}";
	return ($template, \%details);
}  # End sub Confirm

sub Edit	{
	#  Display form for editing a reservation
	my ($form) = @_;
	my ($template, %details, $Data, @reservations, $i);

	open (DATAFILE, "$datafile");
	@reservations=<DATAFILE>;
	close DATAFILE;

	@reservations = grep /^$form->{id}~/, @reservations;
	#  Should only return one entry ...
	$Data = SplitReservation($reservations[0]);

	%details = %$Data;
	$details{description} =~ s/<br>/\n/g;
	$details{description} =~ s/<p>/\n\n/g;
	
	$details{script_name} = $admin;

	($details{year}, $details{month}, $details{day}) = inverse_julian_day($Data->{day});

	for ($i=0;$i<=$#Times;$i++)	{
		$details{start_time} .= "<option value=$i";
		$details{end_time} .= "<option value=$i";
		if ($i == $details{start})	{
			$details{start_time} .= " SELECTED";
		}  #  End if
		if ($i == $details{end})	{
			$details{end_time} .= " SELECTED";
		}  #  End if
		$details{start_time} .= ">$Times[$i]\n";
		$details{end_time} .= ">$Times[$i]\n";
	}  #  End for

	for ($i=0;$i<=$#Rooms;$i++)	{
		$details{select_room} .= "<option value=$i";
		if ($i == $details{room})	{
			$details{select_room} .= " SELECTED";
		}  #  End if
		$details{select_room} .= ">$Rooms[$i]\n";
	}  #  End for

	for ($i=1; $i<=12; $i++)	{
		$details{months} .= "<option value=$i";
		if ($i == $details{month})	{
			$details{months} .= " SELECTED";
		}  #  End if
		$details{months} .= ">$MonthOfYear[$i-1]\n";
	}  #  End for

	$template = 'edit';
	return ($template, \%details);
}  # End sub Edit

sub Update	{
	#  Update the new values of the edited reservation
	my ($form) = @_;
	my ($template, %details, @reservations, @todays_res,
		$conflict, $reservation, $Data, $line, $day);

	#  Verify that the new values are OK.
	if ($form->{start} >= $form->{end})	{
		$details{error} .= 
			"<li>Your meeting ends before it starts, or is of zero length.\n";
	} #  End if

	#  Now, look for conference conflicts
	open (DATAFILE, "$datafile");
	@reservations=<DATAFILE>;
	close DATAFILE;
	chomp @reservations;

	@reservations=grep !/^$form->{id}~/ , @reservations; # Get rid of the old version

	$conflict=0;
	$day = julian_day($form->{year}, $form->{month}, $form->{day});

	#  Only need to check against today's reservations
	@todays_res = grep /~$day$/, @reservations;

	foreach $reservation (@todays_res)	{
		$Data = SplitReservation($reservation);

		if ($Data->{room} == $form->{room} &&
			$form->{start} < $Data->{end} &&
			$form->{end} > $Data->{start} )	{
				$conflict = 1;
		} # End if

	}  # end foreach
	if ($conflict)	{
			$details{error}.="<li>There is a conflict with another meeting.\n";
	}  #  End if

	# Then, if it passed, put the stuff in the file
	if ($details{error} eq "")	{

		#  Get a lock on the lock file
		my $lockfile = $datafile . ".lock";
		open (LOCK, ">$lockfile");
		flock LOCK, 2;

		#  Put the unchanged stuff back in
		open (DATAFILE, ">$datafile");
		for $line (@reservations)	{
			print DATAFILE "$line\n";
		}  #  End for
		close DATAFILE;

		#  Take carriage returns out of the description field
		$form->{description} =~ s/[\n\r]/<br>/g;
		$form->{description} =~ s/<br><br>/<p>/g;

		open (DATAFILE, ">>$datafile");

		# Make reservation string
		$reservation = join '~~', 
			$form->{id},$form->{title},$form->{start},$form->{end},
			$form->{name},$form->{email},$form->{room},
			$form->{description},$day;
		print DATAFILE "$reservation\n";
		close DATAFILE;

		#  Release lock
		flock LOCK, 8;
		close LOCK;

		$template = 'redirect';
		$details{URL} = "$user?action=Details&id=$form->{id}";
	} else  {  #  There were error messages
		$template = 'error';
	} # end else

	return ($template, \%details);
} # end sub Update