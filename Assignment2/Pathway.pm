package Pathway;
use Moose;

has 'KEGG_ID' =>(
    is => 'rw',
    isa => 'Str',
    required => 1
);

has 'Pathway_Name' =>(
    is => 'rw',
    isa => 'Str',
);


1;