#!/usr/bin/perl
use strict;

use Data::Dumper;


my $subdirectory = 'trimmed_comments';
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

	#$addr = 'https://alexandrov-g.livejournal.com/280553.html';

	print("Trimming comments for $addr.\n");

	$addr =~ m{/(\d+).html};
	my $post_id = $1;
	my $comments_expr;
	my $comments_file = "../comments/$post_id.dump";
	
	open(my $COMMENTS, '<', $comments_file) || die("Could open comments file $comments_file.\n");
	{
		local $/ = undef;
		$comments_expr = <$COMMENTS>;
	}
	close($COMMENTS);
	trim_comments($post_id, $comments_expr);

	++$post_count;
	#last;
}
close(PLF);
print "$post_count post comments trimmed.\n";


sub trim_comments
{
	my ($post_id, $comments_expr) = @_;
	my $VAR1;
	eval($comments_expr);
	die if $@;
	my %comments = %$VAR1;
	
	my $starting_num_comments = scalar(keys %comments);
	#print("Starting with $starting_num_comments comments.\n");

	my $comments_trimmed;
	do
	{
		$comments_trimmed = 0;
		
		#print("---\n");
		foreach (keys %comments)
		{
			#print("Looking into comment $_.\n");
			my $comment = $comments{$_};
			my $parent = $comment->{parent};
			
			# Kinda fix, needs verification!!!
			if (!defined($parent))
			{
				#print("No parent in $post_id\n");
				$parent = 0;
				$comment->{parent} = 0;
			}
			
			#print("\tParent: $parent.\n");
			
			if ($comment->{keep})
			{
				if ($parent ne '0')
				{
					if (! $comments{$parent}->{keep})
					{
						#print("\tKeeping parent $parent of comment $_.\n");
						$comments{$parent}->{keep} = 1;
						$comments_trimmed = 1;
					}
					else
					{
						#print("\tParent $parent of comment $_ is already kept.\n");
					}
				}
				else
				{
					#print("\tTop-level comment.\n");
				}
				#print("\tAlready kept.\n");
				next;
			}
			
			if ($comment->{uname} eq 'alexandrov_g')	# Note the underscore
			{
				#print("\talexandrov_g!\tKept.\n");
				$comment->{keep} = 1;
				if ($parent ne '0')
				{
					#print("\tParent $parent kept.\n");
					$comments{$parent}->{keep} = 1;
				}
				else
				{
					#print("\tTop-level comment.\n");
				}
				$comments_trimmed = 1;
			}
			else
			{
				#print("\tLooking for parent $parent of comment $_.\n");
				if ($parent ne '0')
				{
					my $parents_author = $comments{$parent}->{uname} || $comments{$parent}->{dname};
					#print("\tParent's author is $parents_author.\n");
					
					# Actually, don't want to keep answers to the author.
					if (0 && ($parents_author eq 'alexandrov_g'))	# Note the underscore
					{
						#print("\tChild of alexandrov_g.\tKept.\n");
						$comment->{keep} = 1;
						$comments_trimmed = 1;
					}
					else
					{
						#print("\tNot child of alexandrov_g.\tNot kept.\n");
					}
				}
				else
				{
					#print("\tTop-level comment.\tNot kept.\n");
				}
			}
		}
	} while ($comments_trimmed);
	
	my @new_comments;
	foreach (keys %comments)
	{
		my $comment = $comments{$_};
		if ($comments{$_}->{keep})
		{
			my %new_comment = (
				thread => $comment->{dtalkid} || $comment->{thread},
				parent => $comment->{parent},
				author => $comment->{dname} || $comment->{uname},
				comment => $comment->{article},
				subject => $comment->{subject},
				time => $comment->{ctime_ts}
			);
			$new_comment{deleted} = 1 if $comment->{deleted};
			$new_comment{spammed} = 1 if $comment->{leafclass} eq 'spammed';
			push(@new_comments, \%new_comment);
		}
	}
	
	my $file = "$post_id.trimmed";
	open(my $OUTPUT, ">$file") || die "Couldn't open file $file: " . $!;
	print($OUTPUT Dumper(\@new_comments));
	close($OUTPUT);
}
