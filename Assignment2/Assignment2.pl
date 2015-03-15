#!perl
use strict;
use warnings;
use Moose;
use LWP::Simple;  # creates the command ÔgetÕ
use InteractionNetwork;
use Protein;
use ProteinFactory;

#Get the filename
my $protein_data_file= $ARGV[0];

my $factory = ProteinFactory->new(
                    Filename => $protein_data_file,
                    );  # the protein database is automatically loaded by the BUILD method of the Moose object


my $protein_data= $factory -> Proteins; #hash containing the protein objects
my %protein_network; #hash of interacting network objects
my $protein_network = \%protein_network;
my $unassigned_proteins=1; #is 1 if there are still proteins which interact, but haven't been included in a network. Is 0 if all are already included
my $network_id=0; #initialized the key for the %protein_network hash

while ($unassigned_proteins==1){ #this loop is repeated while there are proteins with interactions but not included in a network
    $unassigned_proteins=0; #restarts the value
    
    my $current_size=0; #initial values for current_size and new_size are set, so that the program enters the next while loop
    my $new_size= 1;
    
    while ($current_size != $new_size) { #the loop is done while there are proteins included in the network each round
        if (exists $protein_network -> {$network_id}) {
        #if this hash element is already created, current_size takes the value of the size of the network
        #this hash is created once the loop has been done one time (for each $network_id)
            my @network_list= @{$protein_network -> {$network_id} -> Proteins}; #extracts the initial list of proteins in the network
            $current_size= scalar @network_list; #size of the initial network
        }
        else {$current_size= 0;} #if the hash hasn't been created (the first time the loop is executed), the size of the initial network is set to 0
        
        
        #For each protein in the list, the method add_protein_network is called:
        foreach my $protein (keys%{$protein_data}){
            $protein_network= $protein_data -> {$protein} -> add_protein_network($protein_data,$protein_network,$network_id);
            #the method checks if the protein or one in its Interactions attribute is in the current network
        }
        
    
        if (exists $protein_network -> {$network_id}) {
            my @network_list= @{$protein_network -> {$network_id} -> Proteins}; #updates the value of the network list
            $new_size= scalar @network_list; #extracts the new size of the hash, after the possible addition of interactions
        }
        else {last;} #if this network hasn't been created, it means that there is no protein with interactions that hasn't been already included in one network yet
    }
        
    $network_id++; #the next network needs a new id
    
    foreach my $protein (keys%{$protein_data}){ #checks if there are proteins that still need to be included in a network
        if ($protein_data -> {$protein} -> interacts and $protein_data -> {$protein} -> In_Network == 0) {
        #they need to interact with at least one protein and not be in a network yet
            $unassigned_proteins = 1; #if there is at least one protein with interactions that isn't in any network, the while loop must continue
        }
    }
}


foreach my $network(keys%{$protein_network}){
   $protein_network -> {$network} -> delete_redundant; #deletes the replicated proteins within a network
   $protein_network= $protein_network -> {$network} -> select_file_proteins($protein_network, $network); #leaves in the network only the proteins read from the file
   #sends the hash and the key, so that the method can delete the networks that only have one protein after the selection
}


#Constructs the KEGG pathways and the GO annotation
foreach my $network(keys%protein_network){ 
    $protein_network -> {$network} -> get_pathways;
    $protein_network -> {$network} -> get_GO_annotation;
}


