use strict;
use warnings;
use Data::Dumper;

sub read_file {
    while (1) {
	my $file = "./hs_hand.log";
	open(FH, "<", $file) or (sleep(1) and next);
	my @file_contents = <FH>;
	
	system("clear");
	print @file_contents;
	sleep 2;
    }
}

read_file();
