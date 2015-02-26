#!perl
use strict;
use warnings;
use Gene;
use SeedStock;
use HybridCross;
use Time::Piece; #module necessary to get the date (in plant_seeds subroutine)
#use SeedStockDatabase;

# get the 4 filenames
my $gene_data_file = $ARGV[0];
my $stock_data_file = $ARGV[1];
my $cross_data_file = $ARGV[2];
my $new_stock_data_filename = $ARGV[3];


my $gene_data = &load_gene_data($gene_data_file); # call load data subroutine
# $gene_data is a hashref $gene_data(Gene_ID) = $Gene_Object

my $stock_data = &load_stock_data($stock_data_file, $gene_data); # call load data subroutine
# $stock_data is a hashref of $stock_data(Stock_ID) = $SeedStock_Object

#my $database= SeedStockDatabase ->new(); #create a new SeedStockDatabase object
#$database -> load_from_file($stock_data_file, $gene_data); #this object contains the stock information of the given file
#$database -> write_database($new_stock_data_filename); #method that prints the database object in a new file

##WARNING: the object doesn't work, because the method doesn't send the $gene_data reference correctly.


&plant_seeds($stock_data, 7); # current stock data, plant 7 grams
# this line calls on a subroutine that updates the status of every seed record in $stock_data

&print_new_stock_report($stock_data, $new_stock_data_filename); # current stock data, new database filename
# the line above creates the file new_stock_filename.tsv with the current state of the genebank
# the new state reflects the fact that you just planted 7 grams of seed...

&process_cross_data($cross_data_file, $stock_data);
# the line above tests the linkage. The Gene objects become updated with the other genes they are linked to.

print "\n\nFinal Report:\n\n";

foreach my $gene(keys %{$gene_data}){ # for each of the genes in the gene_data hash
    
 if ($gene_data->{$gene}->has_linkage){ # only process the Gene Object if it has linked genes
 
    my $gene_name = $gene_data->{$gene}->Gene_Name; # get the name of that gene (Gene_Name is a Property)
    my $LinkedGenes = $gene_data->{$gene}->Linkage_to; # get the Gene objects that are linked to it
    
    foreach my $linked(@{$LinkedGenes}){ # dereference the array, and then for each of the array members
      my $linked_name = $linked->Gene_Name; # get it's name using the Gene_Name property
      print "$gene_name is linked to $linked_name\n"; # and print the information
    }
 }
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


sub load_gene_data{
#Reads the lines of a file and creates an object Gene out of each of them.
#Input: file
#Output: hash reference with the Genes_ID as keys.

#Variables:
my $file= shift; #file of the genes
my %Gene; #hash containing the Gene objects

#Tries to open the file and prints an error if it can't:
my $success= &open_file($file); #success is true if the file can be opened.
unless ($success){die "The file doesn't exist: $! \n";} #if $success is not true the program stops and prints an error

my @text= <FILEHANDLE>; #the array contains every line in the file

for (my $i=1; $i<scalar(@text); $i++){ #Starts in line 1 because line 0 contains the title of the columns.
    chomp $text[$i]; #erases the carriage return of the line
    
    my @element = split ("\t", $text[$i]); #every line is splited in its columns, which are separated by \t
    
    #Creation of an object Gene for every line:
    my $object = Gene -> new(
        Gene_ID => $element[0], #the first column corresponds to the gene id
        Gene_Name => $element[1], #the second column has the gene name
        Mutant_Phenotype => $element[2], #the third column explains the mutant phenotype
    );
    
    $Gene{$object->Gene_ID}= $object; #every time an object is created, it is saved in the hash %Gene with its ID as the key.
}

return \%Gene; #the reference to the hash with the objects is returned
}


sub load_stock_data{
#Reads the lines of a file and creates an object SeedStock out of each of them.
#Input: stock file and gene data
#Output: hash reference with the Seeds_ID as keys.

#Variables:
my $file= shift;
my $gene_data= shift;
my %Seed; #hash containing the Seed objects

#Tries to open the file and prints an error if it can't:
my $success= &open_file($file); #success is true if the file can be opened.
unless ($success){die "The file doesn't exist: $! \n";} #if $success is not true the program stops and prints an error

my @text= <FILEHANDLE>; #the array contains every line in the file

for (my $i=1; $i<scalar(@text); $i++){ #Starts in line 1 because line 0 contains the title of the columns.
    chomp $text[$i]; #erases the carriage return of the line
    
    my @element = split ("\t", $text[$i]); #every line is splited in its columns, which are separated by \t
    
    my $gene= $gene_data -> {$element[1]}; #stores the object of the mutated gene of this seed (to use it as value for the attribute Mutant_Gene_ID)
    #the name of the gene mutated in each seed is in the second column -> element[1]
    
    #Creation of an object SeedStock for every line:
    my $object = SeedStock -> new(
        Seed_ID => $element[0],
        Mutant_Gene_ID => $gene, #the Mutant_Gene_ID is an object Gene
        Last_Planted => $element[2],
        Storage => $element[3],
        Grams_Remaining => $element[4],
    );
    
    $Seed{$object->Seed_ID}= $object; #every time an object is created, it is saved in the hash %Seed with the Seed_ID as the key.
}

return \%Seed; #the reference to the hash with the objects is returned
}


sub plant_seeds{
#Substracts the specified number of seeds of the SeedStock objects.
#Input: hash with the SeedStock objects and the number of seeds to substract.
#Output:hash reference of the new stock data

my $stock_data= shift; #current stock data
my $num_seeds= shift; #number of seeds to be planted

my $date= localtime-> strftime ('%d/%m/%Y'); #gets the local time using the module Time::Piece and saves it in the format dd/mm/yyyy

my %stock_data= %{$stock_data}; #dereferenciation of the hash containing the Seed objects.
my @keys_stock= keys%stock_data; #saves the keys of the hash in an array.

#For each seed, the program tries to substract the seeds. If it is successful, the date of the last planted is updated too:
foreach my $seed(@keys_stock){ 
    my $current_grams= $stock_data{$seed} -> Grams_Remaining; #stores the current number of grams of each Seed object
    my $current_seed= $stock_data{$seed} -> Seed_ID; #saves the ID of the current seed (to be able to inform of the seeds that run out)
    
    if ($current_grams== 0) { #if there aren't any grams left, it prints a message and doesn't substract anything (and the date isn't updated)
        print "WARNING: we have run out of Seed Stock $current_seed. It couldn't be planted. \n";
    }
    elsif ($current_grams< $num_seeds){ #if there are less grams than the number intended to plant, it prints a message and plants what is left. 
        print "WARNING: There aren't $num_seeds grams left of the seed $current_seed and only $current_grams grams could be planted. \n";
        $stock_data{$seed}-> Grams_Remaining(0); #the new number of grams is 0, because all the rest were planted
        $stock_data{$seed} -> Last_Planted($date); #the date of the Last_Planted atributte is set to the actual date
    }
    else { #if there are enough grams, it substracts the number of grams indicated and saves the new number in the object
        my $new_grams= $current_grams - $num_seeds; #substraction
        $stock_data{$seed}-> Grams_Remaining($new_grams); #updates the number of grams remaining
        $stock_data{$seed} -> Last_Planted($date); #the date of the Last_Planted atributte is set to the actual date
    }
}

return \%stock_data; #returns the reference of the updated hash with the Seed objects
}


sub print_new_stock_report{
#Prints the data of the stock hash in a file (with the name given)
#Input: reference of the hash with the stock data and the new filename.

my $stock_data= shift; #reference of the stock hash
my $new_stock_data_filename= shift; #new filename

my %stock_data= %{$stock_data}; #dereference of the hash
my @keys_stock_data= keys%stock_data; #saves the keys of the hash in an array

#Prints the titles of the columns first:
my $first_line= "Seed_Stock\tMutant_Gene_ID\tLast_Planted\tStorage\tGrams_Remaining"; #names of the file columns
&print_file($first_line, $new_stock_data_filename);  #calls the subroutine that prints a file (or appends it to an existing file)

#For each value in the hash prints the information of the object (separated by \t) in the new file:
foreach my $stock(@keys_stock_data){
    my $stock_line= $stock ."\t". $stock_data{$stock}->Mutant_Gene_ID ."\t". $stock_data{$stock}->Last_Planted ."\t". $stock_data{$stock}->Storage ."\t". $stock_data{$stock}->Grams_Remaining;
    &print_file($stock_line, $new_stock_data_filename); #calls the subroutine that prints a file (or appends it to an existing file)
}
}


sub print_file{
#Prints a scalar in a new file, or appends it to an existing one.
#Input: 1. Scalar with the information to print; 2. Name of the outfile.

my ($output, $name)= @_; #scalar with the information to print, name of the outfile

open (OUTFILE, ">>$name"); #opens the file in the write mode
print OUTFILE "$output\n"; #prints the information stored in $output in the opened file

return;
}


sub process_cross_data{
#Processes the data of the given file to test if two genes are linked (with a chi square test) by taking the data of the genotypes in the second generation
#Input: file with the cross data and the stock data.

my $cross_data_file= shift; #file containing the seed crosses
my $stock_data= shift; #reference of the hash of the Seed objects

my $cross_data= &load_cross_data($cross_data_file, $stock_data); #creates HybridCross objects with the information in the file and saves them in a hash reference.

my %cross_data= %{$cross_data}; #dereference of the hash containing the HybridCross objects
my @keys_cross_data= keys%cross_data; #keys of the cross_data hash

#For each hybrid object, a Chi square test is done, to test if the mutated genes of the seeds are linked:
foreach my $hybrid(@keys_cross_data){
    #obtains the number of plants in the second generation of each type for this cross:
    my $F2_Wild= $cross_data{$hybrid} -> F2_Wild;
    my $F2_P1= $cross_data{$hybrid} -> F2_P1;
    my $F2_P2= $cross_data{$hybrid} -> F2_P2;
    my $F2_P1P2= $cross_data{$hybrid} -> F2_P1P2;
    
    #calculates the total sum of plants in the second generation:
    my $total_sum= $F2_Wild + $F2_P1 + $F2_P2 + $F2_P1P2;
    
    #if the genes are linked, the expected values are F2_Wild= 9/16, F2_P1= 3/16, F2_P2= 3/16, F2_P1P2= 1/16
    #calculates the expected values for each type in this population, by multiplying the total number of seed with the expected percent of each type
    my $expected_wild= $total_sum * (9/16);
    my $expected_P1= $total_sum * (3/16);
    my $expected_P2= $total_sum * (3/16);
    my $expected_P1P2= $total_sum * (1/16);
    
    #CHI SQUARE TEST:
    #first calculates the formula ((observed - expected)²/ expected) for each type of plant:
    my $chi_wild= (($F2_Wild-$expected_wild)**2)/ $expected_wild;
    my $chi_P1= (($F2_P1-$expected_P1)**2)/$expected_P1;
    my $chi_P2= (($F2_P2-$expected_P2)**2)/$expected_P2;
    my $chi_P1P2= (($F2_P1P2-$expected_P1P2)**2)/$expected_P1P2;
    
    #sum of the four values:
    my $chi_square= $chi_wild + $chi_P1 + $chi_P2 + $chi_P1P2; #value of the chi square test
    
    
    #H0: Genes are NOT linked (the given distribution is not significantly different of the independent distribution 9:3:3:1)
    #H1: Genes are linked
    #if the genes are linked, the chi square value has to be higher than 7.81 (with a level of significance of 0.05 and 3 degrees of freedom)
    if ($chi_square>7.81) {
        
        #if chi square is higher than 7.81 (the genes are linked), the information of the genes involved must be obtained to print the result:
        #1º: The names of the seeds with the linked genes are obtained from the HybridCross objects:
        my $Parent1= $cross_data{$hybrid} -> Parent1; #name of the parent seed 1
        my $Parent2= $cross_data{$hybrid} -> Parent2; #name of the parent seed 2
        
        #2º: The name of the genes linked are obtained from the Seed objects:
        my $gene1= $Parent1 -> Mutant_Gene_ID; #id of the gene mutated in the two parents
        my $gene2= $Parent2 -> Mutant_Gene_ID;
        
        #Addition of the linked gene to the attribute Linkage_to of the object of the FIRST gene
        if ($gene1->has_linkage) { #if this gene already has a linked gene, the new one is added to the array
            my @link= @{$gene1-> Linkage_to}; #saves the array with the already linked genes of the object in $gene1
            push (@link, $gene2); #adds the new gene to the list
            $gene1-> Linkage_to(\@link); #changes the linked genes attribute with the new list
        }
        else {$gene1 -> Linkage_to([$gene2]);} #if there was no gene already anotated as linked, this gene is the new value for the attribute Linkage_to
        
        #Addition of the linked gene to the attribute Linkage_to of the object of the SECOND gene
        if ($gene2->has_linkage) { #if this gene already has a gene linked, the new one is added to the array
            my @link= @{$gene2-> Linkage_to}; #saves the array with the linked genes of the object in $gene2
            push (@link, $gene1); #adds the new linked gene
            $gene2-> Linkage_to(\@link); #changes the old list with the updated one
        }
        else {$gene2 -> Linkage_to([$gene1]);} #if there was no gene already anotated as linked, this gene is the new value for the attribute Linkage_to
    
        #Report:
        print "Recording: ".$gene1->Gene_Name." is genetically linked to ".$gene2->Gene_Name." with chisquare score $chi_square.\n";
    }
    
}

}


sub load_cross_data{
#Reads the lines of a file and creates an object HybridCross out of each of them.
#Input: cross file and stock data
#Output: hash reference with the HybridCross objects

#Variables:
my $file= shift; #file with the information of the crosses
my $stock_data= shift; #reference to the hash with the Seed objects
my %Cross; #hash containing the HybridCross objects

#Tries to open the file and prints an error if it can't:
my $success= &open_file($file); #success is true if the file can be opened
unless ($success){die "The file doesn't exist: $! \n";} #if $success is not true the program stops and prints an error

my @text= <FILEHANDLE>; #the array contains every line in the file

my $i;
for ($i=1; $i<scalar(@text); $i++){ #Starts in line 1 because line 0 contains the title of the columns
    chomp $text[$i]; #erases the carriage return of the line
    
    my @element = split ("\t", $text[$i]); #every line is splited in its columns, which are separated by \t
    
    #the type of the attributes Parent1 and Parent2 is am object Seed:
    #stores the object of the parent seed (to use it as value for the attributes of the parents)
    my $Parent1= $stock_data -> {$element[0]}; #the first parent is in the firs column
    my $Parent2= $stock_data -> {$element[1]}; #the second parent is in the second column
    
    #Creation of a object HybridCross for every line:
    my $object = HybridCross -> new(
        Parent1 => $Parent1, #the parents are seed objects
        Parent2 => $Parent2,
        F2_Wild => $element[2],
        F2_P1 => $element[3],
        F2_P2 => $element[4],
        F2_P1P2 => $element[5],
    );
    
    $Cross{"$i"}= $object; #every time an object is created, it is saved in the hash %Cross with the index $i as key.
}

return \%Cross; #reference to the hash containing the HybridCross objects
}


exit 1;