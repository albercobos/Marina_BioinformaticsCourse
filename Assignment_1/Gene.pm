package Gene;
use Moose;

has 'Gene_ID' => (
    is => 'rw',
    isa => 'Str',
    required => 1,
    trigger => \&test_format_id #every time the attribute's value is set, the subrutine test_format_id is called
);

has 'Gene_Name' => (
    is => 'rw',
    isa => 'Str',
);

has 'Mutant_Phenotype' => (
    is => 'rw',
    isa => 'Str',
);

has 'Linkage_to' => (
    is => 'rw',
    isa => 'ArrayRef[Gene]', #must be a list of gene objects
    predicate => 'has_linkage',
);


sub test_format_id{
#Tests if the format of the object ID matches the Arabidopsis format.

my $self= shift;
my $gene_ID= $self -> Gene_ID; #obtains the id of the current gene

#If the id doesn't match the following regular expression, it triggers an error indicating it has the wrong format and the program dies
unless($gene_ID =~ /A[Tt]\d[Gg]\d\d\d\d\d/){ 
    die "Error: The gene ID $gene_ID doesn't have the Arabidopsis format."
    } 
}

1;