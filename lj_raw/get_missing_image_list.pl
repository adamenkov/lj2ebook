#!/usr/bin/perl
use strict;

use HTML::TokeParser;
use LWP;
use utf8;

binmode(STDOUT, "utf8");

my $ua = LWP::UserAgent->new();
my $post_count = 0;
my $page_list_file = "page_list.txt";
open(my $PLF, "<:encoding(UTF-8)", $page_list_file) || die "Couldn't open $page_list_file: " . $!;
while (<$PLF>)
{
	my $addr = <$PLF>;
	chomp($addr);
	<$PLF>;
	print_missing_images_list($addr);
	++$post_count;
}
close($PLF);
print "$post_count posts processed.\n";


sub print_missing_images_list
{
	my ($addr, $images) = @_;
	#print("Processing $addr:\n");
	$addr =~ m{/(\d+.html)};
	my $file = "posts/$1";
	open(my $INPUT, "<:encoding(UTF-8)", $file) || die "Couldn't open input file $file: " . $!;
	<$INPUT>;
	<$INPUT>;
	local $/ = undef;
	my $post = <$INPUT>;	
	close($INPUT);
	return extract_image_links($addr, $post);
}

sub extract_image_links
{
	my ($addr, $post) = @_;
	my $token_stream = HTML::TokeParser->new(\$post);
	while (my $token = $token_stream->get_token())
	{
		if (($token->[0] eq 'S') && ($token->[1] eq 'img'))
		{
			my $image = $token->[2]{src};
			my $response = $ua->head($image);
			if (!$response->is_success)
			{
				print("На странице $addr\n\tне найдена картинка $image\n");
			}
		}
	}
}
