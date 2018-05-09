#!/usr/bin/perl

############Example command:overview.pl /bin ^b ###########
if(scalar(@ARGV)<2){
	die "At least two parameters should be input\n";
}
else{
	if(!-d $ARGV[0]){
		die "No such dirctory\n";
	}
	else{
		$dirctory = shift @ARGV;	
	}
}
#find and du size of $namepattern in $dirctory
open(temp, ">temp.txt");

while($namepattern = shift @ARGV){ #get each namepattern
	my @find = qx{du -k `find "$dirctory" -type f 2>/dev/null` | sort -n -r}; 
	#find the file under the given dirctory exclude the 'permission denied'
	$flag = "no"; #set flag as whether the namepattern matching or not
	foreach $file (@find){
		chomp $file; #delete following \n 
		$file =~ m!^(.*)/([^/]*)$!; #regular expression:get the string be seperated by the last '/'
		$file_name = $2; #get filename behind the last '/'
		$1=~ /\t/; #regular expression: get the string be seperated by the tab
		$file_size = $`; #get the filesize before tab
		$file_location = $'; #get the location after tab
		$file_name =~ $namepattern;#regular expression for checking the namepattern whether matched
		if("$&" ne "\t"){ #if unmatched "$&" would be \t
			$file_owner = `find "$dirctory" -name "$file_name" -printf '%u' 2>/dev/null`; #get the file owner
			print temp "$file_name\t$file_size\t$file_location\t$file_owner\n";
			$flag = "yes";
		}
	}
	if($flag eq "yes"){
		$pattern .= "$namepattern\t"; #give matched pattern
		$flag = "no";
	}
}
close(temp);

$HIS =<<EOF;
set terminal png size
set grid
set output 'histogram.png'
set style data histograms
set xtic rotate by -45
plot './temp.txt' using 2:xtic(1) with impulses lw 5 title 'histogram of file size(KB)'
EOF
`echo "$HIS" | gnuplot>/dev/null 2>&1`;
#use gnuplot draw histogram

open(OVERVIEW, ">overview.html");
$HTML = <<HTML;
<HTML>
<HEAD>
	<TITLE>Overview</TITLE>
	<H1>Name of dirctory: $dirctory</H1>
</HEAD>
<BODY>
	<H2>Histogram</H2>
	<img src="./histogram.png"></img>
	<H3>Only files matching the following pattern(s):</H3>
	<H4>$pattern</H4>
	<table>
		<tr>
			<td>File</td><td>Size(KB)</td><td>Location</td><td>Ownership</td>
		</tr>
HTML
print OVERVIEW $HTML;

open(temp1, "<temp.txt");
while(<temp1>){
	@output =split /\t/,$_;
	$link = @output[2]."/".@output[0];
	print OVERVIEW "<tr><td><a href=$link>@output[0]</a></td><td>@output[1]</td><td>@output[2]</td><td>@output[3]</td></tr>";
}#print detail of each file in a table
close(temp1);

$HTML1 = <<HTML1;		
	</table>
</BODY>
</HTML>
HTML1
print OVERVIEW $HTML1;

close(OVERVIEW);