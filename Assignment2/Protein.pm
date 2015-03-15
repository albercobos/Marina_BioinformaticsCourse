package Protein;
use Moose;
use LWP::Simple;  # creates the command ‘get’
use strict;
use warnings;
use ProteinFactory;

has 'Protein_ID' => (
    is => 'rw',
    isa => 'Str',
    required => 1,
    #trigger => \&test_format_id, #every time the attribute's value is set, the subrutine test_format_id is called
);

has 'Interactions' => ( #list of proteins that interact whith it
    is => 'rw',
    isa => 'ArrayRef[Protein]',
    predicate => 'interacts',
);

has 'In_Network' => ( #used to check if the protein is included in an interaction network
    is => 'rw',
    isa => 'Int', #if it is already in an interaction network, this attribute equals 1; if not it is 0.
    default => 0,  
);

has 'Factory' => ( #Protein factory which created the protein
    is => 'rw',
    isa => 'ProteinFactory'
);

has 'In_File' => ( #used to check if this protein is in the protein list read from the file
    is => 'rw',
    isa => 'Str',
    predicate => 'protein_in_file'
);

sub test_format_id{
    #Tests if the format of the object ID matches the Arabidopsis format.
    
    my $self= shift;
    my $protein_ID= $self -> Protein_ID; #obtains the id of the current protein
    
    #If the id doesn't match the following regular expression, it triggers an error indicating it has the wrong format and the program dies
    unless($protein_ID =~ /A[Tt]\d[Gg]\d\d\d\d\d/){ 
        die "Error: The protein ID $protein_ID doesn't have the Arabidopsis format."
        } 
}

sub download_interactions{
#Downloads the list of interations of a given protein, creates protein objects for each of them and saves them in the Interactions attribute of the given protein.

    my $self= shift;
    my @protein_interactions; #list of interacting proteins
    my @interactors; #list of locus names, that contains the interacting proteins and itself (in each interaction also saves its own name)
    
    my $protein_id= $self -> Protein_ID; #gets its protein name
    my $record = get("http://www.ebi.ac.uk/Tools/webservices/psicquic/intact/webservices/current/search/query/$protein_id"); #searches in IntAct for its interactions
    
    unless ($record eq ""){ #the list of interactions is only created if at least one interaction exists    
        @interactors= ($record=~ /\|uniprotkb:(.{1,10})\(locus name\)/gs); #searches the position where the protein name is located in the record.
        #{,10} indicates that you can find from 0 to 10 characters in that place
        #"g" indicates that it continues searching in the text even if it has already found a hit -> saves each hit in a different array position
        #"s" ignores carriage returns
    
        foreach my $interactor(@interactors){ #for each hit with the regular expression, it checks if it is the $protein_id and only keeps the different ones
            #this is necessary because in each interaction report is given the name of the indicated protein and the name of the protein that interacts with it
            chomp $interactor;
            unless (uc $protein_id eq uc $interactor){ #only if it is different from the protein_id, it will be saved in the array
                push @protein_interactions, $interactor;
            }
        }
        
        my $factory= $self -> Factory; #gets the name of the factory where this protein was build
        $factory -> add_protein(\@protein_interactions, $protein_id); #this method will check if each of this proteins is already a protein object. If not it will build it.
        #sends the protein_id too, so that the method is able to add the list of Protein objects as value for its Interactions argument
    }
}
    

sub add_protein_network{
    
    my ($self, $protein_data, $protein_network, $network_id)= @_;
    my $protein_id= $self -> Protein_ID; #id of the protein studied at the time
    
    if ($protein_data -> {$protein_id} -> interacts and $protein_data -> {$protein_id} -> In_Network == 0) {
    #checks if the protein has some interaction and has not been added to a network yet. If not, there is no need to look for an interaction network.
            
            my $interactions_list= $protein_data -> {$protein_id} -> Interactions; #list of Protein objects that interact with the current one
            my @interactions_list= @{$interactions_list};            
            unshift @interactions_list, $protein_data->{$protein_id}; #adds itself to the list, to compare it with the rest of the network as well
            
            if (exists $protein_network -> {$network_id}) { #checks if this network already exists -> if not, the network will be created.
            #if it exists, the proteins in it will be compared with the @interactions_list
            
                my $network_list= $protein_network -> {$network_id} -> Proteins; #extracts the list of proteins in this network
                my $match= &find_interaction(\@interactions_list, $network_list); #calls the subroutine that looks for matches between two lists
                    
                if ($match == 1) { #if one interacting protein matches another one of the network ($match=1), its list of interacting proteins is added to that network
                    push @{$network_list}, @interactions_list; #list of proteins in the network is extended
                    $protein_network -> {$network_id} -> Proteins($network_list); #the list of proteins in the interation network is updated
                    
                    $protein_data -> {$protein_id} -> In_Network(1); #indicates that this protein is already in one network
                    return $protein_network; #a protein must be added only to one network in order to avoid duplicates -> the method ends here
                    }
                                    
                elsif ($match == 0){ #this protein doesn't interact with any of this network
                    return $protein_network; #the method ends here
                    }
            }
            
            else { #if this network doesn't exist (with this $network_id), it is created with the current interactions
                my $network_object= InteractionNetwork ->new(
                    Proteins => \@interactions_list,
                    );
                $protein_network -> {$network_id}= $network_object;
                
                $protein_data -> {$protein_id} -> In_Network(1); #indicates that this protein is already in one network
                return $protein_network; #the method ends here
            }
    }
    else {return $protein_network;} #if the protein is already in one network, or doesn't interact at all, the same protein_network hash is given back
}


sub find_interaction{
my ($protein_list_1, $protein_list_2)= @_;
my $match= 0; #initializes its value. Becomes 1 if there are two common proteins in the lists. 

foreach my $protein_1(@{$protein_list_1}){ 
    foreach my $protein_2(@{$protein_list_2}){
    #each protein of the first list is compared with each one of the second
    
        if (uc $protein_1 eq uc $protein_2) { 
            $match=1; #if two proteins match, the value of $match changes and it doesn't need to continue comparing
            return $match;
        }
        
    }
}
return $match;
}

1;