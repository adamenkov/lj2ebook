#!/usr/bin/perl
use strict;

use Data::Dumper;


my $subdirectory = 'sorted_comments';
mkdir($subdirectory) unless -d $subdirectory;
chdir($subdirectory);

my $page_list_file = '../page_list.txt';
open(my $PLF, "<:encoding(UTF-8)", $page_list_file) || die "Couldn't open $page_list_file: " . $!;

my $post_count = 0;
while (<$PLF>)
{
	my $addr = <$PLF>;
	chomp($addr);
	<$PLF>;

	#$addr = 'http://alexandrov-g.livejournal.com/194380.html';

	print("Sorting comments for $addr.\n");

	$addr =~ m{/(\d+).html};
	my $post_id = $1;
	my $comments_expr;
	my $comments_file = "../trimmed_comments/$post_id.trimmed";
	open(my $COMMENTS, '<', $comments_file) || die("Could open comments file $comments_file: " . $!);
	{
		local $/ = undef;
		$comments_expr = <$COMMENTS>;
	}
	close($COMMENTS);
	
	sort_comments($post_id, $comments_expr);

	++$post_count;
	#last;
}
close(PLF);
print "$post_count post comments sorted.\n";


sub sort_comments
{
	my ($post_id, $comments_expr) = @_;
	my $VAR1;
	eval($comments_expr);
	die if $@;
	my @comments = @$VAR1;
	
	$_->{children} = [] foreach (@comments);
	
	my $comments_touched;
	do
	{
		$comments_touched = 0;
		#print("---\n");
		
		foreach (@comments)
		{
			my $thread_id = $_->{thread};
			my $parent_id = $_->{parent};
			
			#print("Looking at comment $thread_id, parent $parent_id.\n");
			
			if ($parent_id)
			{
				my @parents = grep { $_->{thread} == $parent_id } @comments;
				die if (scalar(@parents) != 1);
				my $parent = shift(@parents);
				my $children = $parent->{children};
				my @children_like_me = grep { $_->{thread} == $thread_id } @$children;
				if (scalar(@children_like_me) < 1)
				{
					push(@$children, $_);
					if (scalar(@$children) > 1)
					{
						my @sorted_children = sort { $a->{time} <=> $b->{time} } @$children;
						$parent->{children} = \@sorted_children;
					}
					#print(Dumper(\@comments) . "\n");
					$comments_touched = 1;
				}

				#print(Dumper(\@comments));
				#exit(0);
			}
		}
	} while ($comments_touched);
	
	my @root = grep { $_->{parent} == 0 } @comments;
	my @sorted_root = sort { $a->{time} <=> $b->{time} } @root;
	
	my $file = "$post_id.sorted";
	open(my $OUTPUT, ">$file") || die "Couldn't open file $file: " . $!;
	print($OUTPUT Dumper(\@sorted_root));
	close($OUTPUT);
}
