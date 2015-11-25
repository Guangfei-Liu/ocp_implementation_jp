#!/usr/bin/perl
###
### Usage : ./AsciiDocSplitter.pl SourceFilePath OutputDirectory
### ./AsciiDocSplitter.pl 03_Installation/00_Module03_Complete.adoc 03_Installation/
### This script just takes a .adoc file and splits it to seperate files every
### time it encounters "^== " (regex). It will also populate an AllSlides.txt file.
### To update the "complete" file with the slides, run:
###  cat `ls *.adoc | grep -v 00_` > 00_Module0x_Complete.adoc

if (@ARGV <2)
	{
	print("Usage : ./AsciiDocSplitter.pl SourceFilePath OutputDirectory \n");
	die("not enough arguments\n");
	}

# VARS
$AUTHORNAME="Shachar Borenstein";
$DEBUG=1;
chomp ($SOURCEFILE=$ARGV[0]);
chomp ($DEFAULT_OUTPUT_DIR=$ARGV[1]); system("mkdir -p $DEFAULT_OUTPUT_DIR");
$current_index_file="${DEFAULT_OUTPUT_DIR}/AllSlides.txt";
if (-e $current_index_file)
	{
	$DEBUG && print "Index file already exists\n";
	system("rm $current_index_file");
	open(CURRENTINDEXFILE,">>",$current_index_file);
	}
	else
	{
	$DEBUG && print "Creating new IndexFile: $INDEXNAME\n";
	open(CURRENTINDEXFILE,">>",$current_index_file);

	}
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
		$line =~ s/\?//g;
		$line =~ /^== (.*)$/;
		$pretty_current_page_name = $current_page_name=$1;
		if ($current_page_name =~ /nbsp/) {$pretty_current_page_name = $current_page_name = "Title" ; }
		$current_page_name =~ tr/ /_/; # we substitute spaces with _
		$DEBUG && print "Found Page $page_counter: $line \n";
		$current_file_name="${DEFAULT_OUTPUT_DIR}/${page_counter}_${current_page_name}.adoc";
		$DEBUG && print "File will be named: $current_file_name\n";
		open(CURRENTFILE,">",$current_file_name) or die("could not open: $current_file_name\n");



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
