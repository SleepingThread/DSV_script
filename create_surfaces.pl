#!/usr/bin/perl -w

use MdmDiscoveryScript;
use strict;

sub strip
{
    my ($line) = @_;
    $line =~ s/^\s+//;
    $line =~ s/\s+$//;
    return $line;
}

sub goUntil {
	(my $fin, my $end_line) = @_;
	while(my $row=<$fin>)
	{
		if ($row =~ /^\Q$end_line/)
		{
			return;
		}
	}
}

sub makeSurfaceFile {
	(my $tempfilename, my $molid, my $path) = @_;
	
	#open this file and resave
	my $filename=$tempfilename;
	open(my $fin,'<',$filename) or 
		do{
			print "Cannot open file ".$filename."\n";
			return;
		};

	goUntil($fin,"# Triangle Mesh definition");
	while(my $row=<$fin>)
	{
		if ($row =~ /^point \[.*/)
		{
			last;
		}
	}

	open(my $points,'>',$path."/".$molid.".points") or die "Cannot open .points file";

	while(my $row=<$fin>)
	{
		if ($row =~ /^\].*/)
		{
			last;
		}
		$row = strip($row);
		#write to points
		print $points $row."\n";
	}
	close $points;
	
	
	while(my $row=<$fin>)
	{
		if ($row =~/^coordIndex \[.*/)
		{
			last;
		}
	}
	
	open(my $mesh_index,'>',$path."/".$molid.".meshidx") or die "Cannot open .meshidx file";
	
	while(my $row=<$fin>)
	{
		if ($row =~/^\].*/)
		{
			last;
		}
		$row = strip($row);
		print $mesh_index $row."\n";
	}
	close $mesh_index;
	
	close $fin;
	
} 

#read path $ARGV[0]
#read last id $ARGV[1]

my $arglen = @ARGV;

if ($arglen < 2){
	print "Error: usage create_surfaces <path> <last id number>\n";
	print "Use <last id number> <= 0 if you don't know amount of .mol files\n";
	print "Program will read 1.mol 2.mol ... \n";
	print "   until file doesn't exists or <mol file id> > <last id number> > 0\n";
	exit(1);
}

my $path = $ARGV[0];
my $last_id = $ARGV[1]+0;

my $tmpfilename = $path."/temp.wrl";

my $i=1;

while(1)
{
	my $cur_filename = $path."/".$i.".mol";
	
	if (not -e $cur_filename)
	{
		print "No file ".$cur_filename."\n";
		if ($last_id<=0)
		{
			print "Last file number: ".($i-1)."\n";
			last;
		} else{
			next;
		}
	} else {
		print "Process file ".$cur_filename."\n";
	}
	
	my $document = DiscoveryScript::Open({Path=>$cur_filename});
	
	my $atom_array = $document->Molecules()->Item(0)->Atoms();
	
	my $surface = $document->CreateSolidSurface($atom_array,Mdm::surfaceStyleSolvent,False,
		Mdm::surfaceColorByElectrostaticPotential,1.4);
	
	$document->Save($tmpfilename,'wrl');

	makeSurfaceFile($tmpfilename,$i,$path);
	
	$i++;
	
	if ($last_id>0)
	{
		if ($i>$last_id)
		{
			last;
		}
	}
	
}

#clear temp file
unlink $tmpfilename or warn "Cannot delete file $tmpfilename: $!";

exit();