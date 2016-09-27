#!/usr/bin/perl
use strict;

use HTML::TokeParser;


my %images;
my $post_count = 0;
my $page_list_file = "../lj_raw/page_list.txt";
open(my $PLF, "<:encoding(UTF-8)", $page_list_file) || die "Couldn't open $page_list_file: " . $!;
MAIN_LOOP:
while (<$PLF>)
{
	my $addr = <$PLF>;
	#$addr = "http://alexandrov-g.livejournal.com/291090.html";
	
	chomp($addr);
	<$PLF>;
	
	$addr =~ m{/(\d+).html};
	my $post_number = $1;
	
	# Skip some pages with lost images - see "process_posts.pl".
	foreach (qw(366 832 2678 4054 4181 7558 13638))
	{
		next MAIN_LOOP if $_ eq $post_number;
	}
	
	get_image_list($addr, \%images);
	++$post_count;
	
	#last;
}
close($PLF);
print "$post_count posts processed.\n";
my $image_list_file = "youtube_image_list.txt";
open(my $ILF, ">:encoding(UTF-8)", $image_list_file) || die "Couldn't open image list file $image_list_file: " . $!;
foreach (keys(%images)) {
	print($ILF "$_\n");
}
close($ILF);


sub get_image_list
{
	my ($addr, $images) = @_;

	print("Processing $addr:\n");
	$addr =~ m{/(\d+.html)};
	my $file = "../lj_processed/processed_posts/$1";
	open(my $INPUT, "<:encoding(UTF-8)", $file) || die "Couldn't open input file $file: " . $!;
	local $/ = undef;
	my $post = <$INPUT>;	
	close($INPUT);
	return extract_image_links($post, $images);
}

sub extract_image_links
{
	my ($post, $images) = @_;
	while ($post =~ m|<object type="application/x-shockwave-flash" width="\d+" height="\d+"><param name="movie" value="https://www.youtube.com/v/(.{11})"/>|sg)
	{
		printf("Got one: $1\n");
		$images->{$1} = 1;
	}
}
