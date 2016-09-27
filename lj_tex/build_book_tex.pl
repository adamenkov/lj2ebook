#!/usr/bin/perl
use strict;
use utf8;

my $post_lower_bound = 0;
my $post_upper_bound = 300000;

my %excluded_posts = {};
my $epub_excluded_posts_file = '../lj_processed/epub_excluded_posts_list.txt';
open(my $EPLF, "<:encoding(UTF-8)", $epub_excluded_posts_file) || die "Couldn't open EPUB excluded posts list file $epub_excluded_posts_file: " . $!;
while (<$EPLF>)
{
	chomp($_);
	$excluded_posts{$_} = 1;
}
close($EPLF);

my $pdf_excluded_posts_file = 'pdf_excluded_posts_list.txt';
open($EPLF, "<:encoding(UTF-8)", $pdf_excluded_posts_file) || die "Couldn't open PDF excluded posts list file $pdf_excluded_posts_file: " . $!;
while (<$EPLF>)
{
	chomp($_);
	$excluded_posts{$_} = 1;
}
close($EPLF);

my $book_file = "alexandrov-g.tex";
open(my $BOOK_FILE, ">:encoding(UTF-8)", $book_file) || die "Couldn't open output file $book_file: " . $!;

my $book_start_file = "book_start.tex";
open(my $BOOK_START_FILE, "<:encoding(UTF-8)", $book_start_file) || die "Couldn't open input file $book_start_file: " . $!;
{
	local $/ = undef;
	my $book_start = <$BOOK_START_FILE>;
	print($BOOK_FILE $book_start);
}
close($BOOK_START_FILE);

my $post_count = 0;
my $page_list_file_name = "../lj_raw/page_list.txt";
open(my $PAGE_LIST_FILE, "<:encoding(UTF-8)", $page_list_file_name) || die "Couldn't open $page_list_file_name: " . $!;
while (<$PAGE_LIST_FILE>)
{
	my $http_addr = <$PAGE_LIST_FILE>;
	chomp($http_addr);
	<$PAGE_LIST_FILE>;
	
	$http_addr =~ m{/(\d+).html};
	my $post_number = $1;
	
	#$post_number = 290792;

	next if $excluded_posts{$post_number};
	
	next if $post_number < $post_lower_bound;
	next if $post_number > $post_upper_bound;
	
	print($BOOK_FILE "\\input\{sections/$post_number\}\n");
	
	print("Added post $post_number.\n");
	
	++$post_count;
	#last if $post_count == 5;
	#last;
}
close($PAGE_LIST_FILE);
print("The books has $post_count posts.\n");

my $book_end_file = "book_end.tex";
open(my $BOOK_END_FILE, "<:encoding(UTF-8)", $book_end_file) || die "Couldn't open input file $book_end_file: " . $!;
{
	local $/ = undef;
	my $book_end = <$BOOK_END_FILE>;
	print($BOOK_FILE $book_end);
}
close($BOOK_END_FILE);

close($BOOK_FILE);
