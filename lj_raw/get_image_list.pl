#!/usr/bin/perl
use strict;

use HTML::TokeParser;


my %images;
my $post_count = 0;
my $page_list_file = "page_list.txt";
open(my $PLF, "<:encoding(UTF-8)", $page_list_file) || die "Couldn't open $page_list_file: " . $!;
while (<$PLF>)
{
	my $addr = <$PLF>;
	#my $addr = "http://alexandrov-g.livejournal.com/291559.html";
	
	chomp($addr);
	<$PLF>;
	get_image_list($addr, \%images);
	++$post_count;
	
	#last;
}
close($PLF);
print "$post_count posts processed.\n";
my $image_list_file = "image_list.txt";
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
	my $file = "posts/$1";
	open(my $INPUT, "<:encoding(UTF-8)", $file) || die "Couldn't open input file $file: " . $!;
	<$INPUT>;
	<$INPUT>;
	local $/ = undef;
	my $post = <$INPUT>;	
	close($INPUT);
	return extract_image_links($post, $images);
}

sub extract_image_links
{
	my ($post, $images) = @_;
	my $token_stream = HTML::TokeParser->new(\$post);
	while (my $token = $token_stream->get_token())
	{
		if (($token->[0] eq 'S') && ($token->[1] eq 'img'))
		{
			my $image = $token->[2]{src};
			print("Found $image", "\n");
			$images->{$image} = 1;
		}
	}
}
