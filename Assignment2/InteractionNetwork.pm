package InteractionNetwork;
use Moose;
use LWP::Simple;  # creates the command ÔgetÕ
use JSON;
use Pathway;
use GO;
use Protein;

has 'Proteins' => ( #list of proteins in the network
    is => 'rw',
    isa => 'ArrayRef[Protein]'
);

has 'Pathways' => ( #list of KEGG pathways in which the proteins in the network take part
    is => 'rw',
    isa => 'ArrayRef[Pathway]',
);

has 'GO' => ( #GO annotations of the proteins in the network
    is => 'rw',
    isa => 'GO',
);


sub delete_redundant{
#Deletes the duplicated proteins in a network
    my ($self)= @_;
    my @network_list= @{$self -> Proteins};
    
    my %non_redundant;  # for holding the non-redundant list  
    foreach my $protein(@network_list){
          $non_redundant{$protein->Protein_ID} = $protein; 
    }
    @network_list = values %non_redundant;  # now @list has only one copy of each
    #saves the values (Protein objects), because the keys are just the reference

    $self -> Proteins(\@network_list); #updates the value of the network with the non redundant list
}


sub select_file_proteins{
#Changes the list of proteins in the network, to leave only the proteins read from the file
    my ($self, $protein_network, $network_key)= @_;
    my @file_proteins;
    
    my @network_list= @{$self -> Proteins}; #initial list of proteins in the network
    foreach my $protein(@network_list){ 
        if ($protein -> protein_in_file) { #checks the attribute In_File to know if this protein was build from the file (and not from an interaction)
            push @file_proteins, $protein;
        }
    }
    $self -> Proteins(\@file_proteins); #updates the interaction network only with the "original" proteins
    
    if (scalar @{$self -> Proteins} == 1) { #if after the selection the network only has one protein, this network is deleted (is not a network anymore!)
        delete $protein_network -> {$network_key};
    }
    return $protein_network;
}


sub get_pathways{
#Extracts the information of the pathways in which the proteins of the network take part    
    my ($self)= @_;
    my @network_list= @{$self -> Proteins}; #proteins in the network
    my %pathway_objects; #hash containing Pathway objects
    my @pathway_list; #list of Pathway objects in which this network takes part
    
    foreach my $protein(@network_list){ #searches the pathways for all the proteins in the network
        my $protein_id= $protein -> Protein_ID;
        my $record = get("http://togows.dbcls.jp/entry/genes/ath:$protein_id/pathways.json");
        
        my $json = JSON->new;
        my $ref_content = $json->decode( $record );
        my $refs = $ref_content->[0]; #saves the hash ref that contains the pathways
        #the keys of the hash are the KEGG pathways ID 
        
        foreach my $pathway_id(keys%{$refs}){ #for every pathway, an object is created and saved in the hash %pathway_objects
            my $new_pathway= Pathway->new(
                KEGG_ID => $pathway_id,
                Pathway_Name => $refs -> {$pathway_id}  
            );
            $pathway_objects{$pathway_id}= $new_pathway;
            
            push @pathway_list, $new_pathway; #the pathways of this network are saved in this list
        }
        $self -> Pathways(\@pathway_list); #the list of pathways is set in the Pathways attribute of the network
    }
}


sub get_GO_annotation{
    my ($self)=@_;
    my @network_list= @{$self -> Proteins};
    
    foreach my $protein(@network_list){
        my $protein_id= $protein -> Protein_ID;
    
        #Extracts Uniprot identifier of each protein:
        my $record = get("http://www.ebi.ac.uk/tools/dbfetch/dbfetch?db=ensemblgenomesgene&format=embl&id=$protein_id"); 
        die "can't find a cross-ref UniProt" unless $record =~ /db_xref="Uniprot\S+:(\S+)"/s;
        my $UniProt = $1;
        
        
        #Extracts the GO identifier:
        my $s = get("http://togows.dbcls.jp/entry/uniprot/$UniProt/dr.json");  # this is all exactly the same as before
        my $json = JSON->new;     
        my $perl_scalar = $json->decode( $s );
        my $refs = $perl_scalar->[0];
        
        #print join "\n",  keys %{$refs};
        
        my $intact_annots = $refs->{GO};
        my @go= @{$intact_annots};
        foreach (@go){
            my @go_element= @{$_};
            
            #print "GO: $go_element[0]\n";
        }
        
    }
}

1;
