#!/usr/bin/perl 
use RCBowen::CGI;
use Conference;
use Time::JulianDay;
use Time::CTime qw(:DEFAULT @MonthOfYear);
use strict 'vars';

my %Form=();

PrintHeader();
FormParse(\%Form);

my @Actions = ('Display','Reserve','Add','Details',
				'Edit','Update','Delete','Confirm');

my $routine = Switch($Form{action}, \@Actions, 'Display');
my ($template, $details) = &{$routine}(\%Form);
PrintTemplate($templates, $template, $details);

#############################

sub Display	{
	#  Display the events for 'today'.
	my ($form) = @_;
	my ($template, %details, @reservations,
		$reservation, $room, $hour, $reserve,
		$duration, $Data);
	
	if ($form->{today} eq "")	{
		$form->{today} = local_julian_day(time);
	}

	%details = %$form;

	$details{reserve_link} =
		"$base_url/$script?action=Reserve&today=$form->{today}";
	$details{today_text} = 
		strftime('%A, %B %o, %Y',
				 localtime(jd_secondslocal($form->{today},0,0,0)));
	$details{yesterday} = $form->{today}-1;
	$details{tomorrow} = $form->{today}+1;
	$details{script_name}= $script;

	open (DATAFILE, $datafile);
	@reservations=<DATAFILE>;
	close DATAFILE;
	chomp @reservations;
	
	$details{table} = "<tr><th bgcolor=\"DD519D\">Time</td>\n";

	for $room (@Rooms)	{
		$details{table} .= "<th bgcolor=\"519DDD\">$room</td>\n";
	}  #  End for
	$details{table} .= "</tr>\n";

	for ($hour=0;$hour<=$#Times;$hour++)	{
		$details{table} .= "<tr><td align=middle bgcolor=\"519DDD\">$Times[$hour]</td>\n";
		for ($room=0;$room<=$#Rooms;$room++)  {
			$reserve=0;
			#  Print reservations for that room, that hour
			for $reservation (@reservations)	{
				$Data = SplitReservation($reservation);
				if ($hour >= $Data->{start} && $hour <= $Data->{end}
					&& $room==$Data->{room}	&& $form->{today}==$Data->{day})	{
					$reserve=1;
					if ($hour == $Data->{start})	{
						$duration=($Data->{end}-$Data->{start});
						$details{table} .= qq~
						<td align=middle rowspan=$duration bgcolor="EEEEEE">
						<a href="$base_url/$script?action=Details&id=$Data->{id}">$Data->{title}</a></td>
						~;
						# last;	Not sure why that is there ...
					} # End if
				} # End if
			}  #  End for reservation

			$details{table} .= "<td></td>\n" unless $reserve
		} #  End for room
	$details{table} .= "</tr>\n";
	}  #  End for hour

	$template = 'display';
	return ($template, \%details);
}	# end sub Display


sub Details	{
	#  Display details on a particular conference reservation
	my ($form) = @_;
	my ($template, %details, $reservation, $line, $Data);

	open (DATAFILE, $datafile) or die "Could not open $datafile: $!\n";
	while (<DATAFILE>) {
   		last if (/^$form->{id}/o );
	} #  Wend
	close DATAFILE;

	$Data = SplitReservation($_);
	%details = %$Data;

	$details{room_name} = $Rooms[$details{room}];
	$details{day_text} = 
		strftime('%A, %B %o, %Y',
				 localtime(jd_secondslocal($details{day},0,0,0)));
	$details{email_link} = ($details{email}) ? 
		"<a href=\"mailto:$details{email}\">$details{name}</a>" :
		$details{name};
	$details{schedule_link} = "$base_url/$script?action=Display&today=$details{day}";
	$details{edit_link} = "$base_url/$script?action=Edit&id=$details{id}";
	$details{delete_link} = "$base_url/$script?action=Delete&id=$details{id}";
	$details{'times'} = "$Times[$details{start}] - $Times[$details{end}]";

	$template = 'details';
	return ($template, \%details);
}  # End sub Details


sub Reserve	{
	#	Reserve a particular room
	my ($form) = @_;
	my ($template, %details, $i, $todaytime);
	
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
	$details{script_name} = $script;

	$template = 'reserve';
	return ($template, \%details);
}	# End reserve

sub Add	{
	#  Add reservation to the database
	my ($form) = @_;
	my ($template, %details, @reservations, $conflict,
		$id, $day, $Data, $reservation);

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

		open (DATAFILE, ">>$datafile");
		print DATAFILE "$reservation\n";
		close DATAFILE;

		# Then print an HTML confirmation
		%details = %$form;
		$details{day_text} = 
			strftime('%A, %B %o, %Y',
					 localtime(jd_secondslocal($day,0,0,0)));

		$details{meeting_time} = "$Times[$form->{start}] - $Times[$form->{end}]";
		$details{room_name} = "$Rooms[$form->{room}]";

		$template = 'redirect';
		$details{URL} = "$script?action=Display&today=$day";
	}	else	{ #  There were error messages
		$template = 'error';
		$details{error} .= qq~
		<p>
		There were some problems scheduling your meeting.<br>
		Please go back and try again.
		~;
	}  #  End if ... else

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

	$details{script_name} = $script;
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

	#  Rewrite the datafile
	open (DATAFILE, ">$datafile");
	for (@reservations)	{
		print DATAFILE "$_\n";
	}
	close DATAFILE;

	$Data = SplitReservation($reservation);
	$template = 'redirect';
	$details{URL} = "$script?action=Display&today=$Data->{day}";
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
	
	$details{script_name} = $script;

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
		#  Put the unchanged stuff back in
		open (DATAFILE, ">$datafile");
		for $line (@reservations)	{
			print DATAFILE "$line\n";
		}  #  End for
		close DATAFILE;

		#  Take carriage returns out of the description field
		$form->{description} =~ s/[\n\r]/<br>/g;
		$form->{description} =~ s/<br><br>/<p>/g;

		$day = julian_day($form->{year}, $form->{month}, $form->{day});

		open (DATAFILE, ">>$datafile");

		# Make reservation string
		$reservation = join '~~', 
			$form->{id},$form->{title},$form->{start},$form->{end},
			$form->{name},$form->{email},$form->{room},
			$form->{description},$day;
		print DATAFILE "$reservation\n";
		close DATAFILE;

		$template = 'redirect';
		$details{URL} = "$script?action=Details&id=$form->{id}";
	} else  {  #  There were error messages
		$template = 'error';
	} # end else

	return ($template, \%details);
} # end sub Update

sub goto        {
}
