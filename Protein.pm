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
    trigger => \&download_interactions #every time the attribute's value is set, the subrutine download_interactions is called
);

has 'Interactions' => (
    is => 'rw',
    isa => 'ArrayRef[Str]',
    predicate => 'interacts',
);

has 'In_Network' => (
    is => 'rw',
    isa => 'Int', #if it is already in an interaction network, this atribute equals 1; if not it is 0.
    default => 0,  
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

    my $self= shift;
    my @protein_interactions;
    my @interactors;
    
    my $protein_id= $self -> Protein_ID;
    my $record = get("http://www.ebi.ac.uk/Tools/webservices/psicquic/intact/webservices/current/search/query/$protein_id");
    unless ($record eq ""){    
        @interactors= ($record=~ /\|uniprotkb:(.{1,10})\(locus name\)/gs); #searches the position where the protein name is located in the record.
        #{,10} indicates that you can find from 0 to 10 characters in that position.
        #"g" indicates that it continues searching in the text even if it has already found a hit.
        #"s" ignores carriage returns.
    
        foreach my $interactor(@interactors){
            chomp $interactor;
            unless (uc $protein_id eq uc $interactor){
                push @protein_interactions, $interactor;
            }
        }
        
        $self -> Interactions(\@protein_interactions);
    }
}

sub add_protein_factory{

    my ($self, $protein_data, $protein_factory, $factory_id)= @_;
    print "- Recibe hash protein_factory: $protein_factory \n";
    my $protein_id= $self -> Protein_ID;
    #my %protein_factory= %{$protein_factory};
    my @interactions_list;
    
    if ($protein_data -> {$protein_id} -> interacts and $protein_data -> {$protein_id} -> In_Network == 0) { #checks if the protein has some interaction and has not been added to a factory yet
            my $interactions_ref= $protein_data -> {$protein_id} -> Interactions; #list of proteins that interact with the current one
            my @interactions_list= @{$interactions_ref};            
            unshift @interactions_list, $protein_id; #adds itself to the list, to compare it with the rest of list of interactions
            
            if (exists $protein_factory -> {$factory_id}) { #checks if this factory already exists -> if not, the factory will be created.
                my $factory_list= $protein_factory -> {$factory_id} -> Proteins; #extracts the list of proteins in this factory
                my $match= &find_interaction(\@interactions_list, $factory_list); #calls the subroutine that looks for matches between two lists
                    
                if ($match == 1) { #if one interacting protein matches another one of the factory, its list of interacting protein is added to that factory
                    push @{$factory_list}, @interactions_list;
                    $protein_factory -> {$factory_id} -> Proteins($factory_list);
                    $protein_data -> {$protein_id} -> In_Network(1); #indicates that this protein is already in one factory
                    print "Se añade a la fábrica existente\n";
                    return $protein_factory; #a protein must be added only to one network in order to avoid duplicates
                    }
                                    
                elsif ($match == 0){
                    print "No coincide con la fábrica\n";
                    return $protein_factory;
                    }
            }
            
            else { #if this factory doesn't exist, it is created with the current interactions
                my $factory_object= ProteinFactory ->new(
                    Proteins => \@interactions_list,
                    );
                $protein_factory -> {$factory_id}= $factory_object;
                $protein_data -> {$protein_id} -> In_Network(1); #indicates that this protein is already in one factory
                print "Crea una fábrica: ";
                #my @values= %{$protein_factory{$factory_id}};
                print "@{$protein_factory -> {$factory_id} -> Proteins}";
                print "\n";
                return $protein_factory;
            }
    }
    else {print "Proteína que no interacciona\n";return $protein_factory;}
}


sub find_interaction{

my ($protein_list_1, $protein_list_2)= @_;
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

1;