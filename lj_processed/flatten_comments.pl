#!/usr/bin/perl
use strict;

use Data::Dumper;


my $subdirectory = 'flat_comments';
mkdir($subdirectory) unless -d $subdirectory;
chdir($subdirectory);

my $page_list_file = '../../lj_raw/page_list.txt';
open(my $PLF, "<:encoding(UTF-8)", $page_list_file) || die "Couldn't open $page_list_file: " . $!;

my $post_count = 0;
while (<$PLF>)
{
	my $addr = <$PLF>;
	chomp($addr);
	<$PLF>;

	#$addr = 'https://alexandrov-g.livejournal.com/280553.html';

	print("Flattening comments for $addr.\n");

	$addr =~ m{/(\d+).html};
	my $post_id = $1;
	my $comments_expr;
	my $comments_file = "../../lj_raw/sorted_comments/$post_id.sorted";
	open(my $COMMENTS, '<', $comments_file) || die("Could open comments file $comments_file: " . $!);
	{
		local $/ = undef;
		$comments_expr = <$COMMENTS>;
	}
	close($COMMENTS);
	
	flatten_comments($post_id, $comments_expr);

	++$post_count;
	#last;
}
close(PLF);
print "$post_count post comments flattened.\n";


sub flatten_comments
{
	my ($post_id, $comments_expr) = @_;
	my $VAR1;
	eval($comments_expr);
	die if $@;
	my @comments = @$VAR1;

	my $file = "$post_id.html";
	open(my $OUTPUT, ">:encoding(UTF-8)", $file) || die "Couldn't open file $file: " . $!;
	
	if (scalar(@comments) > 0)
	{
		use utf8;
		print($OUTPUT "<hr/><h4><big>Комментарии</big></h4>");
		
		flatten_recursive($OUTPUT, \@comments);
	}
	
	close($OUTPUT);
}


sub flatten_recursive
{
	my ($OUTPUT, $comments, $parent) = @_;
	
	my $enable_subject_removal = 1;
	my $looped_once = 0;
	foreach (@$comments)
	{
		# Repeating comments doesn't look good - disabling.
		if (0 && $looped_once && !$enable_subject_removal && defined($parent))
		{
			my $out = get_comment($parent, $enable_subject_removal, $parent->{parent});
			$enable_subject_removal = 1;
			print($OUTPUT $out);
		}
		
		my $out = get_comment($_, $enable_subject_removal, $parent);
		$enable_subject_removal = 1;
		print($OUTPUT $out);
		
		my $children = $_->{children};
		if (scalar(@$children) > 0)
		{
			flatten_recursive($OUTPUT, $_->{children}, $_);
		}
		else
		{
			print($OUTPUT "<hr/>\n");
			$enable_subject_removal = 0;
		}
		
		$looped_once = 1;
	}
}


sub get_comment
{
	my ($comment, $enable_subject_removal, $parent) = @_;
	
	my $thread = $comment->{thread};
	my $parent_id = $comment->{parent};
	
	my $author = $comment->{author};
	if ($author eq '')
	{
		use utf8;
		$author = '(Без имени)';
	}
	
	my $subject = $comment->{subject};
	if ($enable_subject_removal && defined($parent))
	{
		my $parent_subject = $parent->{subject};
		$subject = '' if (($subject eq $parent_subject) || ($subject eq ("Re: " . $parent_subject)));
	}
	
	my $text;
	if ($comment->{deleted})
	{
		use utf8;
		$text = "<i>(Удалённый комментарий.)</i>";
	}
	else
	{
		use utf8;
		if ($comment->{spammed})
		{
			$text = "<i>(Комментарий был помечен как спам.)</i>";
		}
		else
		{
			$text = $comment->{comment};

			# Make sure the tag "img" is closed.
			#if ($file eq '757.html') {
			while ($text =~ m|<img (.*?)(/?)>|g)
			{
				if ($2 ne '/')
				{
					my $end = $+[0];
					#print($end);
					substr($text, $end - 1, 1, "/>");
				}
				#print("$post\n");
				#exit(0);
			}
			#}


			# Replace minuses with hypens.
			$text =~ s/ - / – /g;

			$text =~ s/&mdash;/–/g;

			$text =~ s/ & / &amp; /g;
			
			$text =~ s/&nbsp;/ /g;
			$text =~ s/&laquo;/"/g;
			$text =~ s/&raquo;/"/g;
			$text =~ s/&copy;/\(C\)/g;
			$text =~ s/&trade;/\(TM\)/g;
			$text =~ s/&eacute/é/g;
			
			$text =~ s/<span.*?>//g;
			$text =~ s/<\/span>//g;
			
			$text =~ s/<p>/<br\/>/g;
			$text =~ s/<p .*?>/<br\/>/g;
			$text =~ s/<\/p>//g;
			
			$text =~ s/<hr>/<hr\/>/g;
			$text =~ s/<br>/<br\/>/g;
			
			$text =~ s/<br \/>/<br\/>/g;
			$text =~ s/(<br\/>){3,}/<br\/><br\/>/g;
			
			$text =~ s/<\/img>//g;

			# Ad-hoc solution, not super-elegant.
			$text =~ s/Г\.[Аа]\.\s*$//;
			$text =~ s/G\.[Aa]\.\s*$//;
			$text =~ s/(<br\s*\/>\s*)+$//;
			$text =~ s/Г\.[Аа]\.\s*$//;
			$text =~ s/G\.[Aa]\.\s*$//;
			$text =~ s/(<br\s*\/>\s*)+$//;
		}
	}
	
	my $output = "<br/><b>$author</b>";
	if ($subject ne '')
	{
		$output = $output . ", <u>$subject</u>";
	}
	#$output = $output . ": ($thread, parent: $parent_id)<br/>$text<br/>";
	$output = $output . ":<br/>$text<br/>";
	return $output;
}
