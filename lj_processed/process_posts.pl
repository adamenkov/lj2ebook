#!/usr/bin/perl
use strict;
#use Data::Dumper;
use File::Basename;
use utf8;


my %excluded_posts = {};
my $excluded_posts_file = 'epub_excluded_posts_list.txt';
open(my $EPLF, "<:encoding(UTF-8)", $excluded_posts_file) || die "Couldn't open excluded posts list file $excluded_posts_file: " . $!;
while (<$EPLF>)
{
	chomp($_);
	$excluded_posts{$_} = 1;
}
close($EPLF);

my $subdirectory = 'processed_posts';
mkdir($subdirectory) unless -d $subdirectory;
chdir($subdirectory);

my $post_count = 0;
my $page_list_file = "../../lj_raw/page_list.txt";
open(my $PLF, "<:encoding(UTF-8)", $page_list_file) || die "Couldn't open $page_list_file: " . $!;
while (<$PLF>)
{
	my $addr = <$PLF>;
	chomp($addr);
	<$PLF>;
	
	#$addr = "https://alexandrov-g.livejournal.com/280553.html";
	process($addr);
	
	++$post_count;
	#last;
}
close($PLF);
print "$post_count posts processed.\n";


sub process
{
	my $addr = shift;
	$addr =~ m{/(\d+.html)};
	my $file = $1;

	$file =~ m{(\d+).html};
	next if $excluded_posts{$1};

	my $input_file = "../../lj_raw/posts/$file";
	open(my $INPUT, "<:encoding(UTF-8)", $input_file) || die "Couldn't open input file $input_file: " . $!;
	my $title = <$INPUT>;
	chomp $title;
	my $date = <$INPUT>;
	chomp $date;
	$date = get_date_text($date);
	local $/ = undef;
	my $post = <$INPUT>;
	close($INPUT);
	
	# Remove some LiveJournal-related tags.
	$post =~ s/<a name="cutid\d"><\/a>//g;
	$post =~ s/<a name='cutid\d-end'><\/a>//g;

	# Ad-hoc solution, not super-elegant.
	$post =~ s/[ГG]\.[АаAa]\.\s*$//;
	$post =~ s/(<br\s*\/>\s*)+$//;
	$post =~ s/[ГG]\.[АаAa]\.\s*$//;
	$post =~ s/(<br\s*\/>\s*)+$//;
	
	my $comments;
	my $comments_file = "../flat_comments/$file";
	open(my $COMMENTS, "<:encoding(UTF-8)", $comments_file) || die "Couldn't open comments file $comments_file: " . $!;
	{
		local $/ = undef;
		$comments = <$COMMENTS>;
	}
	close($COMMENTS);

	$comments = fix_links($comments);
	$post = fix_links($post);
	my $document = "<?xml version='1.0' encoding='utf-8'?><html xmlns=\"http://www.w3.org/1999/xhtml\"><head><title>$title</title></head><body><div><h2><a href=\"$addr\">$title</a></h2><br/><i>$date</i><br/><br/>$post<br/>$comments</div></body></html>";

	$document = fix_document($document);

	open(my $OUTPUT, ">:encoding(UTF-8)", $file) || die "Couldn't open output file $file: " . $!;
	print($OUTPUT $document);
	close($OUTPUT);
	print "$file processed.\n";
}


sub get_date_text
{
	my @month_name = qw(января февраля марта апреля мая июня июля августа сентября октября ноября декабря);
	my ($year, $month, $day) = split('/', shift);
	$day =~ s/^0//;
	my $month_text = $month_name[$month - 1];
	return "$day $month_text $year";
}


sub fix_document
{
	my $document = shift;
	
	$document = fix_youtube_objects($document);
	$document = fix_images($document);
	
	$document =~ s/&lt;i&gt;/<i>/g;
	$document =~ s/&lt;\/i&gt;/<\/i>/g;
	
	$document = fix_tags($document);
	$document = fix_text($document);

	# Fix paragraph breaks.	
	$document =~ s/(\s*<br\/>\s*){3,}/<br\/><br\/>/g;

	return $document;
}


sub fix_youtube_objects
{
	my $document = shift;

	# Come up with custom "youtube" tags.
	
	$document =~ s|<iframe src="https?://l.lj-toys.com/.*?vid=(.+?)&amp;.*?\s+width="(\d+)"\s+height="(\d+)"\s+.*?</iframe>|<youtube id="$1" width="$2" height="$3"/>|g;
	$document =~ s|<iframe width="(\d+)" height="(\d+)" src="https?://www.youtube.com/embed/(.+?)\?.+?</iframe>|<youtube id="$3" width="$1" height="$2"/>|g;
	$document =~ s|<iframe src="https?://www.youtube.com/embed/(.+?)\?wmode=opaque" width="(\d+)" height="(\d+)".*?</iframe>|<youtube id="$1" width="$2" height="$3"/>|g;
	$document =~ s|<object width="(\d+)" height="(\d+)"><param name="movie" value="https?://www.youtube.com/v/(.+?)["&].+?</object>|<youtube id="$3" width="$1" height="$2"/>|g;

	# Convert the custom "youtube" tags with shockwave objects (readable in iBooks)
	# and iframes (readable in calibre), plus normal links to YouTube
	# for those EPUB readers that can't display embedded video objects.
	
	$document =~ s|<youtube id="(.+?)" width="(\d+)" height="(\d+)"/>|<object type="application/x-shockwave-flash" width="$2" height="$3"><param name="movie" value="https://www.youtube.com/v/$1"/><param name="allowScriptAccess" value="always"/><iframe width="$2" height="$3" src="https://www.youtube.com/embed/$1" frameborder="0"></iframe></object><br/>(<a href="https://www.youtube.com/watch?v=$1">www.youtube.com/watch?v=$1</a>)|g;

	return $document;
}


sub fix_images
{
	my $document = shift;

	# Remove some LiveJournal-related images.
	$document =~ s/<img  class="i-ljuser-userhead".*?>//g;

	# Make local links out of absolute HTTP links.
	while ($document =~ m|<img .*?src="(https?://.*?)"|g)
	{
		my $http_from = $-[1];
		my $http_to = $+[1];

		my $filename = basename($1);
		$filename =~ s/\W/_/g;			# Replace all suspicious characters with the underscore character ...
		$filename =~ s/_png$/\.png/i;	# ... except for the last period, to keep the file's extension (i.e. type).
		$filename =~ s/_gif$/\.gif/i;
		$filename =~ s/_jpg$/\.jpg/i;
		$filename =~ s/_jpeg$/\.jpeg/i;

		if (-e "../images/$filename") {
			substr($document, $http_from, $http_to - $http_from, "../images/$filename"); # Actually replace the link to an image.
		}
	}

	# Make sure the tag "img" is closed.  (Some are not.)
	while ($document =~ m|<img (.*?)(/?)>|g)
	{
		if ($2 ne '/')
		{
			my $end = $+[0];
			substr($document, $end - 1, 1, "/>");
		}
	}

	# Make iTunes Producer (ePub checker) happy.
	# Remove the attribute "border", if present.
	$document =~ s|<img ([^>]*?)\s*border="\d+"(.*?)/>|<img $1 $2/>|g;
	# Remove the attribute "align", if present.
	$document =~ s|<img ([^>]*?)\s*align=".*?"(.*?)/>|<img $1 $2/>|g;
	# Make the attribute "alt" present and equal to the empty string.
	$document =~ s|<img ([^>]*?)\s*alt=".*?"(.*?)/>|<img $1 $2/>|g;
	$document =~ s|<img ([^>]*?)/>|<img alt="" $1/>|g;

	# Remove useless link to photobucket.com - it only disturbs the LaTeX
	$document =~ s|<a href="https?://photobucket\.com/?" target="_blank" rel="nofollow">(.*?)</a>|$1|sg;
	$document =~ s|<a href="https?://smg\.photobucket\.com/albums/v243/alexandrov_g/\?action=view&amp;current=.*?>(.*?)</a>|$1|sg;
	$document =~ s|<a href="https?://smg\.photobucket\.com/user/alexandrov_g/media/.*?>(.*?)</a>|$1|sg;
	$document =~ s|<a href="https?://smg\.beta\.photobucket\.com.*?>(.*?)</a>|$1|sg;

	return $document;
}


sub fix_tags
{
	my $document = shift;
	
	$document =~ s/<br \/>/<br\/>/g;	

	# Make iTunes Producer (ePub checker) happy.
	$document =~ s|<u>(.*?)</u>|<span style="text-decoration:underline">$1</span>|g;
	$document =~ s|<wbr\s*/>||g;
	$document =~ s|<center>(.*?)</center>|<div style="text-align:center">$1</div>|g;
	$document =~ s|<bold>|<b>|g;
	$document =~ s|</bold>|</b>|g;
	$document =~ s|<b>(.*?)</b>|<strong>$1</strong>|g;
	$document =~ s|<i>(.*?)</i>|<em>$1</em>|g;
	$document =~ s|<blockquote>(.*?)</blockquote>|<em>$1</em>|g;
	$document =~ s|<s>(.*?)</s>|<span style="text-decoration:line-through;">$1</span>|g;
	$document =~ s|<strike>(.*?)</strike>|<span style="text-decoration:line-through;">$1</span>|g;
	$document =~ s|<font color="(.*?)">(.*?)</font>|<span style="color:$1">$2</span>|g;

	# Remove XML namespace stuff
	$document =~ s|<xml:namespace ns="livejournal" prefix="lj">||g;
	$document =~ s|</xml:namespace>||g;

	return $document;	
}


sub fix_text
{
	my $document = shift;
	
	# Replace minuses with hypens.
	$document =~ s/ - / – /g;

	# Use the proper symbol for the &.
	$document =~ s/ & / &amp; /g;

	return $document;	
}

sub fix_links
{
	my $document = shift;

	# Replace remote link targets with local posts where possible.
	while ($document =~ m|<a .*?href=['"](https?://alexandrov-g.livejournal.com/.*?)['"]|g)
	{
		my $http_from = $-[1];
		my $http_to = $+[1];
		my $filename = basename($1);
		if (-e "../../lj_raw/posts/$filename") {
			substr($document, $http_from, $http_to - $http_from, $filename);
		}
	}
	return $document;
}
