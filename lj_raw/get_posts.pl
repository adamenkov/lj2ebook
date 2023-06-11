#!/usr/bin/perl
use strict;

use LWP::Simple;


my %force_download;
my @new_files = qw(2864 5115 6466 10910 14907 15367 16249 16842 17328 17744 18315 22617 23471 23925 24473 26414 30768 32481 37003 37988 136146 136441 166320 176831 188812 189146 192098 213161 243980 280553);
foreach (@new_files) {
	$force_download{$_ . ".html"} = 1;
}	


open(my $fh, "<:encoding(UTF-8)", "page_list.txt");
my $subdirectory = 'posts';
mkdir($subdirectory) unless -d $subdirectory;
chdir($subdirectory);
while (<$fh>)
{
	my $addr = <$fh>;
	chomp($addr);
	<$fh>;
	if (download($addr))
	{
		sleep(1);
	}
}
chdir('..');
close($fh);
print 'Done.';


sub download
{
	my $addr = shift;

	$addr =~ m{/(\d+.html)};
	my $file = $1;

	if (-e $file)
	{
		#print("Already exists: $addr.\n");
		#return 0;
		
		#print("Already exists, skipping: $addr.\n");
		next; # unless $force_download{$1};
	}
	
	open(my $OUTPUT, ">:encoding(UTF-8)", "$file") || die "Couldn't open file $file: " . $!;

	my $html = get($addr);
	
	# Extract date
	$html =~ m{https\:\/\/alexandrov-g\.livejournal\.com\/(\d{4})\/(\d{2})\/(\d{2})\/};
	my ($year, $month, $day) = ($1, $2, $3);

	# Extract title and the text
	$html =~ m|<h1.*?>\s*(.*)</h1>.*?<article.*?>(.*?)</article>|s;
	my $title = $1;
	my $text = $2;
	$title =~ s/\s*$//;

	#print "$title\n$year/$month/$day\n";
	print $OUTPUT "$title\n$year/$month/$day\n$text";

	close($OUTPUT);

	print("Downloaded $addr.\n");
	return 1;
}
