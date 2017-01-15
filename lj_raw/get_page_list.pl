#!/usr/bin/perl

use strict;

use Data::Dumper;
use HTML::TokeParser;
use LWP::Simple;

binmode(STDOUT, "utf8");

get_page_list('alexandrov_g', 2004, 2015);


sub get_page_list
{
	my ($journal, $year_from, $year_to) = @_;
	
	my ($year, $month, $addr, $month_view, $token_stream, $token, $table_attrs);
	my ($page_name, $page_addr);

	print("Getting all pages of $journal.livejournal.com, from year $year_from to year $year_to:\n\n");
	open(my $fh, ">:encoding(UTF-8)", "page_list.txt");
	
	for ($year = $year_from; $year <= $year_to; ++$year)
	{
		#print("Year: $year\n");
		
		for ($month = 1; $month <= 12; ++$month)
		{
			#print("Month: $month\n");
			
			$addr = sprintf("http://%s.livejournal.com/%d/%02d/", $journal, $year, $month);
			print("Looking into $addr...\n");
			
			$month_view = get($addr) || die "Couldn't get $addr";
			#print("Month view:\n$month_view"); exit(1);
			
			while ($month_view =~ m|<div class="subjectlist">.*?<a href="(http://alexandrov-g\.livejournal\.com/\d+\.html)">(.*?)</a>|sg)
			{
				print("$2\n$1\n\n");
				print $fh "$2\n$1\n\n";
			}
		}
	}
	
	close($fh);
	print("Done.\n");
}
