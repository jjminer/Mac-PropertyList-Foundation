# $Id: import.t,v 1.3 2006/05/18 00:23:55 comdog Exp $

use Test::More 'no_plan';

require_ok( 'Mac::PropertyList::Foundation' );

ok( ! defined( &parse_plist ), "parse_plist is not defined yet" );
my $result = Mac::PropertyList::Foundation->import( 'parse_plist' );
ok( defined( &parse_plist ), "parse_plist is now defined" );


foreach my $name ( @Mac::PropertyList::Foundation::EXPORT_OK )
	{
	next if $name eq 'parse_plist';
	ok( ! defined( &$name ), "$name is not defined yet" );
	}
	
Mac::PropertyList::Foundation->import( ":all" );

foreach my $name ( @Mac::PropertyList::Foundation::EXPORT_OK )
	{
	ok( defined( &$name ), "$name is now defined yet" );
	}

