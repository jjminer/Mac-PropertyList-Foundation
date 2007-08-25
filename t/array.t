# $Id: array.t,v 1.1 2004/02/03 13:06:24 comdog Exp $

use Test::More tests => 5;

use Mac::PropertyList::Foundation;

########################################################################
# Test the array bits
{
my $array = Mac::PropertyList::Foundation::array->new();
isa_ok( $array, "Mac::PropertyList::Foundation::array", 'Make empty object' );
is( $array->count, 0, 'Empty object has no elements' );
}

my $array =<<"HERE";
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<array>
	<string>Mimi</string>
	<string>Roscoe</string>
	<string>Juliet</string>
	<string>Buster</string>
</array>
</plist>
HERE

$plist = Mac::PropertyList::Foundation::parse_plist( $array );
isa_ok( $plist, "Mac::PropertyList::Foundation::array", "Make object  from plist string" );
is( $plist->count, 4, "Object has right number of values" );

my @values = $plist->values;
ok( eq_array( \@values, [qw(Mimi Roscoe Juliet Buster)] ), 
	"Object has right values" );

