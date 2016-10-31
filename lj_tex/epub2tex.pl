#!/usr/bin/perl
use strict;
use utf8;

use Data::Dumper;


my $post_lower_bound = 0;
my $post_upper_bound = 300000;

my %missing_images = {};
my $missing_images_list_file = 'missing_youtube_image_list.txt';
open(my $MILF, "<:encoding(UTF-8)", $missing_images_list_file) || die "Couldn't open missing image list file $missing_images_list_file: " . $!;
while (<$MILF>)
{
	chomp($_);
	$missing_images{$_} = 1;
}
close($MILF);

my $current_chapter = "";
my %chapter_names = {};
my $chapters_file_name = "chapters.txt";
open(my $CHAPTERS_FILE, "<:encoding(UTF-8)", $chapters_file_name) || die "Couldn't open chapters file $chapters_file_name: " . $!;
while (<$CHAPTERS_FILE>)
{
	my $chapter_number = <$CHAPTERS_FILE>;
	chomp($chapter_number);
	my $chapter_name = <$CHAPTERS_FILE>;
	chomp($chapter_name);
	$chapter_names{$chapter_number} = $chapter_name;
}
close($CHAPTERS_FILE);

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

my $subdirectory = 'sections';
mkdir($subdirectory) unless -d $subdirectory;
chdir($subdirectory);

my $post_count = 0;
my $page_list_file_name = "../../lj_raw/page_list.txt";
open(my $PAGE_LIST_FILE, "<:encoding(UTF-8)", $page_list_file_name) || die "Couldn't open $page_list_file_name: " . $!;
while (<$PAGE_LIST_FILE>)
{
	my $http_addr = <$PAGE_LIST_FILE>;
	chomp($http_addr);
	<$PAGE_LIST_FILE>;
	
	$http_addr =~ m{/(\d+).html};
	my $post_number = $1;
	
	#$post_number = 2233;
	
	next if $excluded_posts{$post_number};
	
	next if $post_number < $post_lower_bound;
	next if $post_number > $post_upper_bound;

	make_tex_section($post_number);	
	
	++$post_count;
	#last if $post_count == 4;
	#last;
}
close($PAGE_LIST_FILE);
print "$post_count posts processed.\n";


sub make_tex_section
{
	my $post_number = shift;

	my $document;
	my $input_file_name = "../../lj_processed/processed_posts/$post_number.html";
	open(my $INPUT_FILE, "<:encoding(UTF-8)", $input_file_name) || die "Couldn't open input file $input_file_name: " . $!;
	{
		local $/ = undef;
		$document = <$INPUT_FILE>;
	}
	close($INPUT_FILE);
	
	$document = epub2tex($document, $post_number);
	
	my $output_file_name = "$post_number.tex";
	open(my $OUTPUT_FILE, ">:encoding(UTF-8)", $output_file_name) || die "Couldn't open output file $output_file_name: " . $!;
	print($OUTPUT_FILE $document);
	close($OUTPUT_FILE);
	
	#
	print "$output_file_name processed.\n";
}


sub epub2tex
{
	my ($document, $post_number) = @_;
	
	$document =~ m{<body>(.*)</div></body></html>}s;
	$document = $1;

	# General
	$document =~ s|&amp;|\\&|g;
	$document =~ s|&gt;|>|g;
	$document =~ s|&quot;|"|g;
	$document =~ s|\$|\\\$|g;
	$document =~ s|%|\\%|g;
	$document =~ s|&#1123;|е|g;	# I couldn't find out how to print old Russian 'e'
	
	# Colors
	$document =~ s|<span style="color:#(\w{6})">(.*?)</span>|\\definecolor\{color$1\}\{HTML\}\{\U$1\E\}\\textcolor\{color$1\}\{$2\}|g;
	$document =~ s|<span style="color:(\w+?)">(.*?)</span>|\\textcolor\{$1\}\{$2\}|g;

	if (exists($chapter_names{$post_number}))
	{
		$current_chapter = $chapter_names{$post_number};
	}
	
	# Section start	
	if ($document =~ m|^<div><h2>(.*?)</h2><br/><em>(.*?)</em><br/><a href=".*?">(.*?)</a><br/><br/>(.*)|s)
	{
		my $name = fix_underscores($1);
		my $date = $2;
		my $url = $3;
		my $rest = $4;
		$document = "\\normalsize\\section\*\{$name\}";
		if ($name !~ /^$current_chapter/)
		{
			$document = $document . "\\addcontentsline\{toc\}\{section\}\{$name\}";
		}
		#$document = $document . "\\markboth\{$name\}\{$name\}\\begin{tabularx\}\{\\textwidth\}\{Xr\}\{\\em $date\} & \\url\{$url\}\\end\{tabularx\}\\medskip\n\n$rest";
		$document = $document . "\\markboth\{$name\}\{$name\}{\\em $date\}\n\n\\url\{$url\}\\medskip\n\n$rest";

		if (exists($chapter_names{$post_number}))
		{
			$document = "\\chapter*\{" . $current_chapter . "\}\\addcontentsline\{toc\}\{chapter\}\{$current_chapter\}\n" . $document;
		}
	}

	# DROP THE COMMENTS IN THE PDF EDITION
	$document =~ s|<br/><hr/><h4><big>Комментарии</big></h4>.*<hr/>||sg;
	
#	# Comments start
#	$document =~ s|<br/><hr/><h4><big>Комментарии</big></h4>(.*)<hr/>|\\footnotesize\\subsection\*\{Комментарии\}$1|sg;
#	
#	# Comment's author
#	while ($document =~ m|(.*)<br/><strong>(.*?)</strong>([,:].*)|s)
#	{
#		$document = "$1\n\\noindent\{\\bfseries " . fix_underscores($2) . "\}$3";
#	}
#	
#	# Comment thread separator
#	$document =~ s|<hr/>|\\noindent\\hrulefill|g;
#	#$document =~ s|<hr/>|\\begin{center}\$\\ast\$~\$\\ast\$~\$\\ast\$\\end{center}|g;
	
	# Hyperlinks
	while ($document =~ m|(.*?)<a .*?href=['"](.*?)['"].*?>(.*?)</a>(.*)|s)
	{
		my $begin = $1;
		my $url = $2;
		my $text = $3;
		my $end = $4;
		my $cmd;
		if (($text =~ /\s/) || ($text =~ m|^https?://.*?|) || ($text =~ m|^www\.|))
		{
			$cmd = "\\texttt\{" . fix_hyperlink($text) . "\}";
		}
		else
		{
			#$cmd = "\\path\{$text\}"
			$cmd = "\\ttfamily $text";
		}
		#print("url: $url\n");
		#print("text: $text\n");
		#print("cmd: $cmd\n");
		$url =~ s/\\$//;
		#print("|$url|\n");
		$document = "$begin\\href\{$url\}\{$cmd\}$end";
	}
	
	$document =~ s|pioneer_lj/(\d+).html\?thread=(\d+)#t(\d+)|pioneer\\_lj/$1.html\?thread=$2\#t$3|g;
	
	# Images
	while ($document =~ m|(.*?)<img .*?src="\.\./Images/(.*?)"\s*/>(.*)|s)
	{
		my $begin = $1;
		my $image_name = $2;
		my $end = $3;
		
		$image_name =~ s/\.gif/\.jpg/g;
		
		$document = $begin . "\\begin\{figure\}\[H\]\\includegraphics\[max height=18 cm,max width=\\linewidth\]\{" . $image_name . "\}\\centering\\end\{figure\}" . $end;	
	}
	
	# YouTube
	while ($document =~ m|(.*?)<object type="application/x-shockwave-flash" width="(\d+)" height="(\d+)"><param name="movie" value="https://www.youtube.com/v/(.{11}).*?"/><param name="allowScriptAccess" value="always"/><iframe width="\d+" height="\d+" src="https://www.youtube.com/embed/.*?" frameborder="0"></iframe></object>(.*)|s)
	{
		my $code = $4;
		if ($missing_images{$code})
		{
			$document = "$1\\begin\{center\}\\framebox\{Видео отсутствует.\}\\end\{center\}$5";
		}
		else
		{
			$document = "$1\\begin\{figure\}\[H\]\\href\{https://www.youtube.com/watch?v=$code\}\{\\includegraphics\[max width=\\linewidth\]\{$code.jpg\}\}\\centering\\end\{figure\}$5";
		}
	}
	
	# <big>
	$document =~ s|<big>|\{\\Large |g;
	$document =~ s|</big>|\}|g;
	
	# <div>
	$document =~ s|<div>(.*?)</div>|$1|sg;
	
	# <em>
	$document =~ s|<em>|\{\\em |g;
	$document =~ s|</em>|\}|g;
	
	# <h2>
	$document =~ s|<h2>|\{\\subsubsection\*\{ |g;
	$document =~ s|</h2>|\}\}|g;
	
	# Lists
	$document =~ s|<ol>|\\begin\{enumerate\}|g;
	$document =~ s|</ol>|\\end\{enumerate\}|g;

	$document =~ s|<li>|\\item |g;
	$document =~ s|</li>||g;

	# <i>
	$document =~ s|<i>|\{\\itshape |g;
	$document =~ s|</i>|\}|g;
	
	# <pre>	
	$document =~ s|<pre>|\\begin\{verbatim\}|g;
	$document =~ s|</pre>|\\end\{verbatim\}|g;

	# <small>
	$document =~ s|<small>|\{\\smaller |g;
	$document =~ s|</small>|\}|g;

	# Strike-through
	$document =~ s|<span style="text-decoration:line-through;">(.*?)</span>|\\sout\{$1\}|g;

	# <strong>
	$document =~ s|<strong>|\{\\bfseries |g;
	$document =~ s|</strong>|\}|g;
	
	# <sub>
	$document =~ s|<sub>|\\textsubscript\{|g;
	$document =~ s|</sub>|\}|g;

	# <sup>
	$document =~ s|<sup>|\\textsuperscript\{|g;
	$document =~ s|</sup>|\}|g;
	
	# Tables
	$document =~ s|<table>|\\begin\{tabbing\}|g;
	$document =~ s|</table>|\\end\{tabbing\}|g;
	
	$document =~ s|<tr>||g;
	$document =~ s|</tr>|\\\\|g;
	
	$document =~ s|<td>||g;
	$document =~ s|</td>| \= |g;
	
	# Underlined text
	$document =~ s|<span style="text-decoration:underline">(.*?)</span>|\\uline\{$1\}|g;
	
	# Centering
	$document =~ s|<div style="text-align:center">(.*?)</div>|\\begin\{center\}$1\\end\{center\}|g;
	
	# Quotes
	$document =~ s|<q>|\{\\em |g;
	$document =~ s|</q>|\}|g;

	$document =~ s|<cite>|\\begin\{quotation\}|g;
	$document =~ s|</cite>|\\end\{quotation\}|g;
	
	$document =~ s|<code>|\\begin\{quotation\}|g;
	$document =~ s|</code>|\\end\{quotation\}|g;

	$document =~ s|<br/>|\n\n|g;

	# Remove all other tags
	if ($document =~ m/(<\/?\w+?.*?>)/s)
	{
		print("$post_number: $1\n");
	}
	#$document =~ s/<.*?>//g;
	
	# Do this after tag removal; otherwise we can get fake tags.
	$document =~ s|&lt;|<|g;
	
	# Fix quote marks
	$document =~ s/"/"\\xspace\{\}/g;

	# Cautious underscore fix
	$document =~ s| _| \\_|g;
	$document =~ s|_ |\\_ |g;
	$document =~ s|_\. |\\_\. |g;
	#$document =~ s|___|\\_\\_\\_|g;
	
	$document =~ s|#|\\#|g;
	
	# Ad-hoc
	$document =~ s|Alexandrov_G|Alexandrov\\_G|g;
	$document =~ s|iv_s|iv\\_s|g;
	$document =~ s|maxim_sokolov|maxim\\_sokolov|g;
	$document =~ s|Русаки_Де|Русаки\\_Де|g;
	$document =~ s|Вьетнамская_Война|Вьетнамская\\_Война|g;
	$document =~ s|Первая_Индокитайская_Война|Первая\\_Индокитайская\\_Война|g;
	$document =~ s|Вторая_Индокитайская|Вторая\\_Индокитайская|g;
	
	return $document;
}


sub fix_underscores
{
	my $string = shift;
	$string =~ s|_|\\_|g;
	return $string;
}


sub fix_hyperlink
{
	my $string = shift;
	$string =~ s|#|\\#|g;
	$string =~ s|(<br/>)+|\\\\\\indent\{\}|g;
	return fix_underscores($string);
}
