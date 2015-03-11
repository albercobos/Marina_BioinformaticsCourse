package HybridCross;
use Moose;
use SeedStock;

has 'Parent1' => (
    is => 'rw',
    isa => 'SeedStock', #must be a SeedStock object
    required => 1,
);

has 'Parent2' => (
    is => 'rw',
    isa => 'SeedStock', #must be a SeedStock object
    required => 1,
);

has 'F2_Wild' => (
    is => 'rw',
    isa => 'Int',
    required => 1, #necessary to calculate the linkage of the genes
    default => 0
);

has 'F2_P1' => (
    is => 'rw',
    isa => 'Int',
    required => 1,
    default => 0
);

has 'F2_P2' => (
    is => 'rw',
    isa => 'Int',
    required => 1,
    default => 0
);

has 'F2_P1P2' => (
    is => 'rw',
    isa => 'Int',
    required => 1,
    default => 0
);

1;