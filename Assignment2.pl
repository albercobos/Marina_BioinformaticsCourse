#!perl
use strict;
use warnings;
use Moose;
use LWP::Simple;  # creates the command ‘get’
use InteractionNetwork;
use Protein;
use ProteinFactory;

#Get the filename
my $protein_data_file= $ARGV[0];

my $protein_data = &load_protein_data($protein_data_file); # call load data subroutine
# $protein_data is a hashref $protein_data(Protein_ID) = $Protein_Object

my %protein_factory;
my $protein_factory = \%protein_factory;
my $unassigned_proteins=1; #is 1 if there are still proteins which interact, but haven't been included in a factory yet. Is 0 if all are already included
my $factory_id=0;

while ($unassigned_proteins==1){
    $unassigned_proteins=0; #restarts the value
    foreach my $protein (keys%{$protein_data}){
        if ($protein_data -> {$protein} -> interacts and $protein_data -> {$protein} -> In_Network == 0) {
            $unassigned_proteins = 1; #if there is at least one protein with interactions that isn't in any factory, the while loop must continue
        }
    }

    my $difference_size_factory=0;
    my $current_size=0; #initial values for current_size and new_size are set, so that the program enters the while loop
    my $new_size= 1;
    
    while ($current_size != $new_size) {
        if (exists $protein_factory -> {$factory_id}) { #if this hash is already created, current_size takes the value of the size of the factory
            #this hash is created once the loop has been done one time
            my @factory_list= @{$protein_factory -> {$factory_id} -> Proteins}; #extracts the initial list of proteins in the factory
            $current_size= scalar @factory_list; #size of the initial factory
            print "no\n";
        }
        else {$current_size= 0;print "si\n";} #if the hash hasn't been created (the first time the loop is executed), the size of the initial factory is set to 0
        
        #For each protein in the list, the method add_protein_factory is called:
        foreach my $protein (keys%{$protein_data}){
            $protein_factory= $protein_data -> {$protein} -> add_protein_factory($protein_data,$protein_factory,$factory_id);
        }
        
        if (exists $protein_factory -> {$factory_id}) {
            my @factory_list= @{$protein_factory -> {$factory_id} -> Proteins}; #updates the value of the factory list
            $new_size= scalar @factory_list; #extracts the new size of the hash, after the possible addition of interactions
        }
        else {last;} #if this factory hasn't been created, it means that there is no protein with interactions that hasn't been already included in one factory yet
    }
    
    $factory_id++; #the next factory needs a new id
}

#Deletes the replicated proteins within a network
foreach my $factory(keys%{$protein_factory}){
    my @factory_list= @{$protein_factory -> {$factory} -> Proteins};
    
    my %non_redundant;  # for holding the non-redundant list  
    foreach (@factory_list){
          $non_redundant{ucfirst $_} = 1;
    }
    @factory_list = keys %non_redundant;  # now @list has only one copy of each
    $protein_factory -> {$factory} -> Proteins(\@factory_list);
    print "FACTORY: @factory_list\n";
}

foreach my $protein (keys%{$protein_data}){
    if ($protein_data -> {$protein} -> interacts and $protein_data -> {$protein} -> In_Network == 0){
        print "ERROR! $protein NO ESTÁ EN LISTA!\n";
    }
}

#########################
#########################
foreach my $protein(keys%{$protein_data}){
    if ($protein_data -> {$protein} -> interacts){
        my @interactions= @{$protein_data -> {$protein} -> Interactions};
        #print $protein_data -> {$protein} -> Protein_ID.":\n@interactions\n";
    }    
}

my @protein_list= keys%{$protein_data};

my $has_changed =1;
my $counter= 0;

foreach my $protein_1(@protein_list){
    if ($protein_data-> {$protein_1}-> interacts) {
        my @protein_list_1= @{$protein_data-> {$protein_1} -> Interactions};
        foreach my $protein_2(@protein_list){
        } 
    }
}


sub find_interaction{

my ($protein_list_1, $protein_list_2)= shift;
my $match= 0; #becomes 1 if there are two common proteins in the lists. 

foreach my $protein_1(@{$protein_list_1}){
    foreach my $protein_2(@{$protein_list_2}){
        if (uc $protein_1 eq uc $protein_2) {
            $match=1;
            last;
        }
        
    }
}

return $match;
}

#########################
#########################


sub load_protein_data{
#Reads the lines of a file and creates an object Protein out of each of them.
#Input: file with one protein per line
#Output: hash reference with the Protein_ID as keys.

#Variables:
my $file= shift; #file of proteins
my %Protein; #hash containing the Protein objects

#Tries to open the file and prints an error if it can't:
open(FILE, "<$file") || die "Can't open protein data file $!\n";

while (my $line= <FILE>){
    chomp $line; #erases the carriage return of the line
    $line= lc $line; $line= ucfirst $line; #makes the protein name lowercase, and then only the first one uppercase (if it is not set to lowercase first and the second letter is originally uppercase, it doesn't change)
    
    #Creation of an object Protein for every line:
    my $protein_object = Protein -> new(
        Protein_ID => $line
    );
    
    $Protein{$protein_object->Protein_ID}= $protein_object; #every time an object is created, it is saved in the hash %Protein with its ID as the key.
}

return \%Protein; #the reference to the hash with the objects is returned
}