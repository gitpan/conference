#!/usr/bin/perl 
use Conference;
use Time::JulianDay;
use Time::ParseDate;
use Time::DaysInMonth;
use Time::CTime qw(:DEFAULT @MonthOfYear);
use strict 'vars';

PrintHeader();
my $form = FormParse;

my @Actions = qw(Display Details Jump
				 );

my $routine = Switch($form->{action}, \@Actions, 'Display');
my ($template, $details) = &{$routine}($form);
PrintTemplate($templates, $template, $details);

#############################

sub Display	{
	#  Display the events for 'today'.
	my ($form) = @_;
	my ($template, %details, @reservations,
		$reservation, $room, $hour, $reserve,
		$duration, $Data, $todaytime, $i);
	
	if ($form->{today} eq "")	{
		$form->{today} = local_julian_day(time);
	}

	%details = %$form;
	$todaytime=jd_secondslocal($form->{today},0,0,0);

	$details{reserve_link} =
		"$base_url/$admin?action=Reserve&today=$form->{today}";
	$details{today_text} = 
		  strftime('%A, %B %o, %Y', localtime($todaytime));
	$details{day} =  strftime('%d', localtime($todaytime));
	$details{year} = strftime('%Y', localtime($todaytime));
	$details{yesterday} = $form->{today}-1;
	$details{tomorrow} = $form->{today}+1;
	$details{script_name}= $user;

	open (DATAFILE, $datafile);
	@reservations=<DATAFILE>;
	close DATAFILE;
	chomp @reservations;
	
	$details{table} = "<tr><th bgcolor=\"DD519D\">Time</td>\n";

	for $room (@Rooms)	{
		$details{table} .= "<th bgcolor=\"519DDD\">$room</td>\n";
	}  #  End for
	$details{table} .= "</tr>\n";

	for ($hour=0; $hour<=$#Times; $hour++)	{
		$details{table} .= "<tr><td align=middle bgcolor=\"519DDD\">$Times[$hour]</td>\n";
		for ($room=0; $room<=$#Rooms; $room++)  {
			$reserve=0;
			#  Print reservations for that room, that hour
			for $reservation (@reservations)	{
				$Data = SplitReservation($reservation);
				if ($hour >= $Data->{start} && $hour < $Data->{end}
					&& $room==$Data->{room}	&& $form->{today}==$Data->{day})	{
					$reserve=1;
					if ($hour == $Data->{start})	{
						$duration=($Data->{end}-$Data->{start});
						$details{table} .= qq~
						<td align=middle rowspan=$duration bgcolor="EEEEEE">
						<a href="$base_url/$user?action=Details&id=$Data->{id}">$Data->{title}</a></td>
						~;
						last; #  If we find a reservation, we can quit looking
					} # End if
				} # End if
			}  #  End for reservation

			$details{table} .= "<td></td>\n" unless $reserve;
		} #  End for room
	$details{table} .= "</tr>\n";
	}  #  End for hour

	$details{month} = strftime('%m', localtime($todaytime));
	for ($i=1; $i<=12; $i++)	{
		$details{months} .= "<option value=$i";
		if ($i == $details{month})	{
			$details{months} .= " SELECTED";
		}
		$details{months} .= ">$MonthOfYear[$i-1]\n";
	}  #  End for

	$template = 'display';
	return ($template, \%details);
}	# end sub Display


sub Details	{
	#  Display details on a particular conference reservation
	my ($form) = @_;
	my ($template, %details, $reservation, $line, $Data);

	open (DATAFILE, $datafile) or 
		die "Could not open $datafile: $!\n";
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
	$details{schedule_link} = "$base_url/$user?action=Display&today=$details{day}";
	$details{edit_link} = "$base_url/$admin?action=Edit&id=$details{id}";
	$details{delete_link} = "$base_url/$admin?action=Delete&id=$details{id}";
	$details{'times'} = "$Times[$details{start}] - $Times[$details{end}]";

	$template = 'details';
	return ($template, \%details);
}  # End sub Details

sub Jump	{
	#  Jump to a particular day
	my ($form) = @_;
	my ($day_time, $day, $template, $details);

	$form->{day} = sprintf "%.2d", $form->{day};
	if ($form->{day} > days_in($form->{year}, $form->{month}))	{
		$form->{day} = days_in($form->{year}, $form->{month});
	}

	$day_time = parsedate("$form->{month}/$form->{day}/$form->{year}");
	$day = local_julian_day($day_time);
	$template = 'redirect';
	$details->{URL} = "$base_url/$user?action=Display&today=$day";

	return ($template, $details);
}  #  End sub Jump
	

	

