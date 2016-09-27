#!/usr/bin/perl

use strict;

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
		for ($month = 1; $month <= 12; ++$month)
		{
			$addr = sprintf("\nhttp://%s.livejournal.com/%d/%02d/", $journal, $year, $month);
			$month_view = get($addr);
			$token_stream = HTML::TokeParser->new(\$month_view);
			while ($token = $token_stream->get_token())
			{
				if (($token->[0] eq 'S') && ($token->[1] eq 'table'))
				{
					$table_attrs = $token->[3];
					if (scalar(@$table_attrs) > 0)
					{
						while ($token = $token_stream->get_token())
						{
							if (($token->[0] eq 'S') && ($token->[1] eq 'a'))
							{
								$page_addr = $token->[2]->{'href'};
								$token = $token_stream->get_token();
								$page_name = $token->[1];
								print "$page_name\n$page_addr\n\n";
								print $fh "$page_name\n$page_addr\n\n";
								last;
							}
						}
					}
				}
			}
		}
	}
	
	close($fh);
	print("Done.\n");
}
