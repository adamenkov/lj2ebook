#!/usr/bin/perl
use strict;

use LWP::Simple;


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
	
	if (-e $1)
	{
		#print("Already exists: $addr.\n");
		#return 0;
		
		#print("Already exists, skipping: $addr.\n");
		next;		
	}
	
	open(my $OUTPUT, ">:encoding(UTF-8)", "$file") || die "Couldn't open file $file: " . $!;

	my $html = get($addr);
	
	# Extract date
	$html =~ m{http\:\/\/alexandrov-g\.livejournal\.com\/(\d{4})\/(\d{2})\/(\d{2})\/};
	my ($year, $month, $day) = ($1, $2, $3);

	# Extract title and the text
	$html =~ m{<h1.*?>\s*(.*)</h1>.*?<article.*?>(.*)</article>};
	my $title = $1;
	my $text = $2;
	$title =~ s/\s*$//;

	# print "$title\n$year/$month/$day\n";
	print $OUTPUT "$title\n$year/$month/$day\n$text";

	close($OUTPUT);

	print("Downloaded $addr.\n");
	return 1;
}
