use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Mac::PropertyList::Foundation',
    license             => 'perl',
    dist_author         => 'Jonathan J. Miner <cpan@jjminer.org>',
    dist_version_from   => 'lib/Mac/PropertyList/Foundation.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
    },
    add_to_cleanup      => [ 'Mac-PropertyList-Foundation-*' ],
);

$builder->create_build_script();
