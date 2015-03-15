package ProteinFactory;
use Moose;
use Protein;

has 'Proteins' =>(
    is => 'rw',
    isa => 'HashRef[Protein]'
);

has 'Filename' => (
    is  =>  'rw',
    isa =>  'Str',
    required => 1,
);



sub BUILD {   # BUILD is a Moose function that is automatically executed after Object->new() has completed.
              # in this case, we are using it to load the object from the file
    
  my ($self) = @_; 
  my $filename = $self->Filename;
  
  open(IN, "<$filename") or die "File $filename failed to open $!\n\n";  # explain failure to open

  my %protein_list;
  while (my $line = <IN>){ #every line contains a protein id
    chomp $line;
    
    my $Factory = Protein->new( #a Protein object is created for every line
        Protein_ID => $line,
        Factory => $self,
        In_File => 'Yes' #attribute that indicates that this protein object was read from the file
    );
    
    $protein_list{$line} = $Factory; #hash containing the Protein objects
  }
  close IN;
  
  $self->Proteins(\%protein_list); #adds the proteins created to the attribute Proteins of this factory
  
  foreach my $protein (keys%protein_list){ 
    $protein_list{$protein} -> download_interactions; #method that looks for the interactions of each protein in IntAct
  }
}


sub add_protein{
#Adds the proteins found in the interactions to the factory and builds their protein objects

    my ($self, $new_proteins, $current_protein)= @_;
    my $protein_list= $self -> Proteins; #proteins already in the factory
    my %protein_list= %{$protein_list};
    my @interaction_list; #list of Protein objects that interact with the current Protein
    
    foreach my $protein (@{$new_proteins}){ 
        unless (exists $protein_list{$protein}){ #for each new protein checks if its object already exists
            #if it is new, creates an object
            my $new_prot= Protein -> new(
                Protein_ID => $protein,
                Factory => $self
            );
            $protein_list{$protein} = $new_prot; #saves its object in the hash
            
        }
        push @interaction_list, $protein_list{$protein}; #adds it to the list of protein objects that interact with the current protein
    }
    $self -> Proteins(\%protein_list); #updates the factory list
    $protein_list{$current_protein} -> Interactions (\@interaction_list); #sets the value of the Interactions attribute for this protein
    
}

1;