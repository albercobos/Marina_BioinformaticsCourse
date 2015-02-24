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
    isa => 'Gene',
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
    required => 1,
    default => 0,
);

1;