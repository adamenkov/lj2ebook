#!/usr/bin/perl
use strict;

use Cwd;
use File::Basename;
use File::Path qw(make_path);
use LWP::Simple;

my $subdirectory = 'images';
mkdir($subdirectory) unless -d $subdirectory;
chdir($subdirectory);

my $image_list_file = "../../lj_raw/image_list.txt";
open(my $ILF, "<:encoding(UTF-8)", $image_list_file) || die "Couldn't open image list file $image_list_file: " . $!;
my $missing_image_list_file = '../missing_image_list.txt';
open(my $MILF, ">:encoding(UTF-8)", $missing_image_list_file) || die "Couldn't open missing image list file $missing_image_list_file: " . $!;

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
print("$image_count images processed.\n");


sub get_image
{
	my $url = shift;
	my $uri = URI->new($url);
	
	my $image_file_name = basename($uri->path());
	$image_file_name =~ s/\W/_/g;
	$image_file_name =~ s/_png$/\.png/i;
	$image_file_name =~ s/_gif$/\.gif/i;
	$image_file_name =~ s/_jpg$/\.jpg/i;
	$image_file_name =~ s/_jpeg$/\.jpeg/i;
	
	if (-e $image_file_name)
	{
		print("Already exists: $image_file_name.\n");
		return 1;
	}
	
	print("Getting $url...\n");
	my $image_data = get($url);
	return 0 unless defined($image_data);
	
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