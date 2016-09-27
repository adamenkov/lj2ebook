#!/usr/bin/perl
use strict;

use Cwd;
use File::Basename;
use File::Path qw(make_path);
use LWP;
use LWP::Simple;
use URI::file;

my $subdirectory = 'comments_images';
mkdir($subdirectory) unless -d $subdirectory;
chdir($subdirectory);

my $comments_image_list_file = "../comments_image_list.txt";
open(my $ILF, "<:encoding(UTF-8)", $comments_image_list_file) || die "Couldn't open image list file $comments_image_list_file: " . $!;
my $missing_comments_image_list_file = '../missing_comments_image_list.txt';
open(my $MILF, ">:encoding(UTF-8)", $missing_comments_image_list_file) || die "Couldn't open missing comments image list file $missing_comments_image_list_file: " . $!;

my $image_count = 0;
while (<$ILF>)
{
	chomp;
	
	if (!get_image($_))
	{
		printf("\tCouldn't download $_!\n");
		print($MILF "$_\n");
	}
	
	++$image_count;
	#last if $image_count == 5;
}
close($MILF);
close($ILF);
print("$image_count comments images processed.\n");


sub get_image
{
	my $url = shift;
	print("Getting $url...\n");
	
	my $image_data = get($url);
	return 0 unless defined($image_data);
	
	my $uri = URI->new($url);
	
	#$url =~ s|http://||;
	#my $dir = dirname($url);
	#make_path($dir);
	#my $orig_cwd = getcwd;
	#chdir($dir);
	my $image_file_name = basename($uri->path());
	$image_file_name =~ s/\W/_/g;
	$image_file_name =~ s/_png$/\.png/i;
	$image_file_name =~ s/_gif$/\.gif/i;
	$image_file_name =~ s/_jpg$/\.jpg/i;
	
	if (open (my $IMAGE_FILE, ">$image_file_name"))
	{
		binmode $IMAGE_FILE;
		print $IMAGE_FILE $image_data;
		close $IMAGE_FILE;
		print("Saved to: $image_file_name\n");
		#chdir($orig_cwd);
		return 1;
	}
	else
	{
		print("\tCouldn't open file $image_file_name!\n");
		#chdir($orig_cwd);
		return 0;
	}
}