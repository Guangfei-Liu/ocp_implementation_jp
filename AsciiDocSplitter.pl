#!/usr/bin/perl
###
### Usage : ./AsciiDocSplitter.pl SourceFilePath [OutputDirectory] [Labs=1|0]
### ./AsciiDocSplitter.pl somelargeascii.adoc myprojectname 0
### ./AsciiDocSplitter.pl somelargeasciiWithLABS.adoc myprojectname 1


#x="05";
#git rm `ls ${x}*/*.adoc ${x}*/AllSlides.txt | egrep -iv 'labs|complete'` ; rm -f ${x}*~ ;
#./AsciiDocSplitter.pl ${x}*/00*.adoc ${x}* ; git add ${x}*/*.adoc ; git add ${x}*/AllSlides.txt  ; git commit -m"Added Module${x} - Ready for Review"


if (@ARGV <1)
	{
	print("Usage : ./AsciiDocSplitter.pl SourceFilePath ImagesSourceDirectory [OutputDirectory] \n");
	die("not enough arguments\n");
	}

# VARS
$AUTHORNAME="Shachar Borenstein";
$DEBUG=1;
chomp ($SOURCEFILE=$ARGV[0]);
chomp ($DEFAULT_OUTPUT_DIR=$ARGV[1]); system("mkdir -p $DEFAULT_OUTPUT_DIR");
$current_index_file="${DEFAULT_OUTPUT_DIR}/AllSlides.txt";
print "Source file to parse : $SOURCEFILE \n";

$page_counter="0";

open(SOURCEFILE,$SOURCEFILE) or die ("Could not open source file");
foreach $line (<SOURCEFILE>)
	{
	if ($line =~ /^==[^=]/) # If line starts with == but not ===
		{
		$DEBUG && print "Found Slide: $line \n";
		close(CURRENTFILE); # we will close the possibly open current file to start a new one
		# un comment this line if you have more than 100 slides. buy why would you.
		#$page_counter = $page_counter + 1; if ($page_counter >= 10) {$page_counter = "0" . $page_counter;  } else {$page_counter = "00" . $page_counter;}
		$page_counter = $page_counter + 1; if ($page_counter >= 10) {$page_counter = "" . $page_counter;  } else {$page_counter = "0" . $page_counter;}

		$line =~ /^== (.*)$/;
		$pretty_current_page_name = $current_page_name=$1;
		if ($pretty_current_page_name =~ /nbsp/) { $pretty_current_page_name = $current_page_name= "Title"; }
		$current_page_name =~ tr/ /_/; # we substitute spaces with _

		$DEBUG && print "Found Page $page_counter: $line \n";
		$current_file_name="${DEFAULT_OUTPUT_DIR}/${page_counter}_${current_page_name}.adoc";
		$DEBUG && print "File will be named: $current_file_name\n";
		open(CURRENTFILE,">>",$current_file_name) or die("could not open: $current_file_name\n");
		#print CURRENTFILE "
#";

	if (-e $current_index_file)
		{
		$DEBUG && print "Index file already exists\n";
		open(CURRENTINDEXFILE,">>",$current_index_file);
		}
		else
		{
		print "Creating new IndexFile: $INDEXNAME\n";
		open(CURRENTINDEXFILE,">>",$current_index_file);
		print CURRENTINDEXFILE
"
:scriptsdir: scormdriver/auto-scripts
:script: AutoBookmark.js
:script: AutoCompleteSCO.js
:script: CourseExit.js


";

		}




		print CURRENTFILE "$line";
		#Added file to index
		print CURRENTINDEXFILE "include::${page_counter}_${current_page_name}.adoc[]\n\n"
		}
	 else
	 {
	 print CURRENTFILE "$line";

	 }
}
print "finished \n";
