use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Mac::PropertyList::Foundation',
    AUTHOR              => 'Jonathan J. Miner <cpan@jjminer.org>',
    VERSION_FROM        => 'lib/Mac/PropertyList/Foundation.pm',
    ABSTRACT_FROM       => 'lib/Mac/PropertyList/Foundation.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Mac-PropertyList-Foundation-*' },
);
