package SeedStockDatabase;
use SeedStock;
use Moose;
use Gene;

has 'SeedStock' => (
    is => 'rw',
    isa => 'HashRef[SeedStock]', #must be a hash reference of SeedStock objects
);


sub load_from_file{

my $self= shift;
my $stock_file= shift; #file of the seed stock
my $gene_data = shift; #reference of the hash containing the gene objects
my %Seed; #hash that stores all the seed objects

#Tries to open the file and prints an error if it can't:
my $success= &open_file($stock_file); #success is true if the file can be opened.
unless ($success){die "The file doesn't exist: $! \n";} #if it couldn't be opened the program dies and prints an error

my @text= <FILEHANDLE>; #the array contains every line in the file

for (my $i=1; $i<scalar(@text); $i++){ #Starts in line 1 because line 0 contains the title of the columns.
    chomp $text[$i]; #erases the carriage return of the line
    
    my @element = split ("\t", $text[$i]); #every line is splited in its columns, which are separated by \t, and saved in the array @element
    
    my $gene= $gene_data -> {$element[1]}; #stores the object of the mutated gene of this seed (to use it as value for the attribute Mutant_Gene_ID)
    #the name of the gene mutated is in the second column of the file -> element[1]
    
    #Creation of an object SeedStock for every line:
    my $object = SeedStock -> new(
        Seed_ID => $element[0],
        Mutant_Gene_ID => $gene, #is a Gene object
        Last_Planted => $element[2],
        Storage => $element[3],
        Grams_Remaining => $element[4],
    );
    
    $Seed{$element[0]}= $object; #every time an object is created, it is saved in the hash %Seed with the Seed_ID as the key.
    
$self -> SeedStock([\%Seed]); #the hash reference is the value of the attribute SeedStock in the database object.
}
}


sub get_seed_stock{
#Gets the information of a seed object by giving its reference

my ($self, $seed)= @_;
my $seed_stock= $self -> SeedStock -> {$seed}; #gets the reference to the SeedStock object of the specified seed

return $seed_stock; #returns the reference to the SeedStock object
}


sub write_database{
#Prints the data of the database object in a file (with the name given)
#Input: new filename

my ($self, $new_filename)= @_;

#Prints the titles of the columns first:
my $first_line= "Seed_Stock\tMutant_Gene_ID\tLast_Planted\tStorage\tGrams_Remaining";
&print_file($first_line, $new_filename); #calls the subroutine that prints in a file (or appends it to an existing file)

#Gets the array containing the seeds in this database:
my @seed_stock= @{$self -> SeedStock};

#For each seed in the database, prints a line with the information of the seed object:
foreach my $seed(@seed_stock){
    my $seed_object= $self -> get_seed_stock($seed); #gets the reference of each seed object
    my $stock_line= $seed ."\t". $seed_object->Mutant_Gene_ID ."\t". $seed_object->Last_Planted ."\t". $seed_object->Storage ."\t". $seed_object->Grams_Remaining;
    &print_file($stock_line, $new_filename); #calls the subroutine that prints in a file (or appends it to an existing file)
}
}


sub print_file{
#Prints a scalar in a new file, or appends it to an existing one.
#Input: 1. Scalar with the information to print; 2. Name of the outfile.

my ($output, $name)= shift; #scalar with the information to print, name of the outfile

open (OUTFILE, ">>$name"); #opens the file in the write mode
print OUTFILE "$output\n"; #prints in the opened file

return;
}


sub open_file{
#Opens a file and makes sure it exists.
#Input: file
#Output: scalar which is only true if the file could be opened.

#Variables:
my $success; #is true if the file can be opened
my $file= shift;

$success= open (FILEHANDLE, "<$file"); #if it can be opened, $success is TRUE.

return $success;
}


1;