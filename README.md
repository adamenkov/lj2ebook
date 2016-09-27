The goal of this project is to make an eBook (EPUB) and a printable book (PDF) from the blog http://alexandrov-g.livejournal.com of Mr. Gennady Alexandrov.

The latest eBook version is right here: [alexandrov-g.epub](https://github.com/adamenkov/lj2ebook/blob/master/alexandrov-g.epub?raw=true).  Also, some recent version of the eBook is available at no cost at [Apple iTunes](https://itunes.apple.com/us/book/imperia.-vlast-.-igra./id1069426062?ls=1&mt=11).  The eBook can be read with: calibre, iBooks (iOS, OS X), ePub Reader (Android), Legimi (Windows Phone).

_The printable (PDF) version of the book is still under construction - use at your own risk._ The latest PDF version is here: [alexandrov-g.pdf](https://github.com/adamenkov/lj2ebook/blob/master/alexandrov-g.pdf?raw=true).

To build the eBook, I used OS X (El Capitan) 10.11.3, Code Runner 1-2, Perl v5.18.2.  To build the PDF, I also used TexLive 1.21 and Texpad 1.4.7.

The files used to build the eBook are as follows:

File | Description
-----|------------
get_page_list.pl | Go through all months in 2004-2015 and extract the LiveJournal post titles and HTTP addresses, put the result in the file page_list.txt.  It should be run only once.
get_posts.pl | Download all posts (without comments) and store them (together with their title and date) in the subdirectory post.  It should be run only once.  If you run it again, all your fixes will be overwritten.
get_image_list.pl | Get the list of all referenced images and put it in the file image_list.txt.
get_missing_image_list.pl | Find all broken links to images and write the list to file missing_image_list.txt.  You don't really want broken images in the eBook.  Some posts are not even decipherable (by readers) without them.
orator.jpg | An image that the author's LiveJournal avatar was made of.  It is a fragment of the caricature "Speaker" by Herluf Bidstrup.
get_comments.pl | Download all comments for further processing offline.
trim_comments.pl | Drop all comments that are not answered by the author.  More specifically, for a comment to remain in the final eBook it must be either written by the author or answered by someone who is answered by someone ... who is answered by the author.
sort_comments.pl | Order comments according to how they were originally at the LiveJournal page.
flatten_comments.pl | In LiveJournal, comments are organized in threads.  For the purposes of this eBook, I decided to insert horizontal lines between groups of comments pertaining to different threads at the original LiveJournal page.
get_comments_image_list.pl | Get the list of all images referenced in the comments (that survived trimming) and store it in the file comments_image_list.txt.
get_comments_images.pl | Download images from the comments_image_list.txt.  Make a list of images that couldn't be downloaded and put it into file missing_comment_image_list.txt.
process_posts.pl | Take downloaded posts (modified to fix typos) and combine them with the flattened comments, do some other fixes to make calibre and iBooks happy.  Output files - in the subdirectory "processed_posts" - are manually inserted in the alexandrov-g.epub using calibre and are also the input files to build the PDF version of the book.
alexandrov-g.epub | The container for the processed posts, images, the table of contents, the page "From the Publisher".

Once a post is edited (e.g. a typo is fixed), process_posts.pl should be run.

Once a comment is edited, (1) trim_comments.pl, (2) sort_comments_pl, (3) flatten_comments.pl, and (4) process_posts.pl should be run.  _I'll need to come up with update_posts.pl (or some kind of makefile) to automate this._

Once a new post by the author (Mr. Alexandrov) is written (this is unfortunately an extremely rare event these days), the easiest way is probably the following: manually add the title and the HTTP address of the new post to the file page_list.txt, run get_posts.pl and the 4 scripts from the previous paragraph.  If the post contains images, we need to download them and the easiest way to do it is probably to generate a new image list (get_image_list.pl with the output file name changed) and download images only from this list (get_images.pl).  If an author's comment (or a comment upward from it) has images, we need to do similar things with get_comments_image_list.pl and get_comments_images.pl.

_If Mr. Alexandrov ever writes another post, I'll come up with a script that automates the generation of the new chapter along with all the referenced images._

For changes to take effect in the EPUB, it should be edited (e.g. one/some/all HTML files should be replaced).  Always run the checks (by calibre and ePub Checker) after every modification.

The files used to build the PDF are as follows:

File | Description
-----|------------
epub2tex.pl | Convert processed posts (see above) from HTML to TeX format, stripping out comments and some irrelevant posts.
book_start.tex | The start LaTeX code of the generated alexandrov-g.tex, to include some LaTeX packages and insert the book cover and the section "From publisher".
cover.tex | The cover of the book.
from_publisher.tex | The section "From publisher".
book_end.tex | The end LaTeX code of the generated alexandrov-g.tex.
build_book_tex.pl | Combine book_start.tex, cover.tex, from_publisher.tex, the result files of epub2tex.pl, and book_end.tex to come up with the alexandrov-g.tex.
chapters.txt | Defines how to break down the book posts into chapters.
get_youtube_image_list.pl | Make the list of YouTube videos referenced in the book that are still available.  In the PDF version of the book, we don't use embedded video objects.  Instead, we just use images and printed HTTP references.
get_youtube_images.pl | Download the cover images of the referenced YouTube videos.
missing_youtube_image_list.txt | Used to come up with a text "Video not available" in the text.
youtube_image_list.txt | List of available YouTube videos.

Evgeny Adamenkov
