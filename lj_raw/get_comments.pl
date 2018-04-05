#!/usr/bin/perl
use strict;

use Data::Dumper;
use JSON;
use LWP::Simple;


my $subdirectory = 'comments';
mkdir($subdirectory) unless -d $subdirectory;
chdir($subdirectory);

my $page_list_file = '../page_list.txt';
open(my $PLF, "<:encoding(UTF-8)", $page_list_file) || die "Couldn't open $page_list_file: " . $!;
my @lines = <$PLF>;
close($PLF);
my $expected_number_of_posts = scalar(@lines) / 3;
undef @lines;

open(my $PLF, "<:encoding(UTF-8)", $page_list_file) || die "Couldn't open $page_list_file: " . $!;

my $post_count = 1;
while (<$PLF>)
{
	my $addr = <$PLF>;
	chomp($addr);
	<$PLF>;
	
	#$addr = "https://alexandrov-g.livejournal.com/218465.html";
	
	$addr =~ m{https://(.*).livejournal.com/(\d+).html};
	my $journal = $1;
	my $post_id = $2;
	
	my $file = "$post_id.dump";
	if (-e $file)
	{
		print("Already downloaded: $file\n");
		next;
	}
	
	print("Processing $addr ($post_count/$expected_number_of_posts).\n");
	
	my $all_comments_ref = {};
	my $processed_threads_ref = {};

	my $page = get($addr);

	my $num_pages = 1;
	my $text = '<a href="/' . $post_id . '.html\?page=';
	my $searched_text;  
	do
	{
		++$num_pages;
		$searched_text = $text . $num_pages . '"';
	} while ($page =~ /$searched_text/s);
	--$num_pages;
	undef $text;
	undef $searched_text;
	print("Found $num_pages page" . (($num_pages > 1) ? 's' : '') . ".\n");
	
	for (my $page_number = 1; $page_number <= $num_pages; ++$page_number)
	{
		print("Processing page $page_number.\n");
		
		if ($page_number > 1)
		{
			$page = get($addr . "?page=$page_number");
		}
		
		$page =~ /Site\.page = ({.*?});/;
		my $json = $1;
		my $post_info = from_json($json);
		my $comments_ref = $post_info->{comments};
	
		download_comments($comments_ref, $all_comments_ref, $processed_threads_ref, $journal, $post_id);
	}
	my $num_comments = scalar(keys %$all_comments_ref);
	print("Found $num_comments comment" . (($num_comments > 1) ? 's' : '') . ".\n\n");

	my $file = "$post_id.dump";
	open(my $OUTPUT, ">$file") || die "Couldn't open file $file: " . $!;
	print($OUTPUT Dumper($all_comments_ref));
	close($OUTPUT);

	++$post_count;
	
	#last;
}

close($PLF);
--$post_count;
print("$post_count pages processed.\n");
chdir('..');


sub download_comments
{
	my ($comments_ref, $all_comments_ref, $processed_threads_ref, $journal, $post_id, $parent) = @_;
	my @threads_to_load;
	
	for my $comment (@$comments_ref)
	{
		if (!defined($comment->{parent}) && defined($parent))
		{
			$comment->{parent} = $parent;
		}
		
		my $thread = $comment->{dtalkid} || $comment->{thread};
		next if defined($thread) && $processed_threads_ref->{$thread};
		#print("Looking at comment with thread = $thread\n");
		
		if ($comment->{more})
		{
			#print("Pushing MORE: " . $comment->{parent} . "\n");
			$processed_threads_ref->{$comment->{parent}} = undef;
			push @threads_to_load, $comment->{parent};
		}
		else
		{
			if (!$comment->{loaded} && !$comment->{deleted} && ($comment->{leafclass} ne 'spammed'))
			{
				#print("Pushing thread: " . $thread . "\n");
				push @threads_to_load, $thread;
			}
			else
			{
				if (!$processed_threads_ref->{$thread})
				{
					$all_comments_ref->{$thread} = $comment;
					$processed_threads_ref->{$thread} = 1;
				}
			}
		}
	}
	
	#print("\nProcessing threads-to-load:\n\n") if (scalar(@threads_to_load) > 0);
	
	for my $thread (@threads_to_load)
	{
		next if $processed_threads_ref->{$thread};
		#print("\nProcessing thread $thread...\n");
		
		my $root = $all_comments_ref->{$thread}->{parent};
		
		my $http =
			"https://www.livejournal.com/$journal/__rpc_get_thread?journal=$journal&itemid=$post_id&flat=&skip=1&thread=$thread&expand_all=1&_=7";
		my $json = get($http);
		my $post_info = from_json($json);
		my $comments_ref = $post_info->{comments};
		download_comments($comments_ref, $all_comments_ref, $processed_threads_ref, $journal, $post_id, $root);
	}
}
