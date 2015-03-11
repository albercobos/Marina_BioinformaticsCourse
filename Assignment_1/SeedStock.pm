package SeedStock;
use Moose;
use Gene;

has 'Seed_ID' => (
    is => 'rw',
    isa => 'Str',
    required => 1,
);

has 'Mutant_Gene_ID' => (
    is => 'rw',
    isa => 'Gene', #must be a gene object
    required => 1,
);

has 'Last_Planted' => (
    is => 'rw',
    isa => 'Str',
);

has 'Storage' => (
    is => 'rw',
    isa => 'Str',
);

has 'Grams_Remaining' => (
    is => 'rw',
    isa => 'Int',
    required => 1, #is required to be able to plant (use the subroutine plant_seeds)
    default => 0, #if its value is not given, it will be set to 0 automatically
);

1;