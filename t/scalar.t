# $Id: scalar.t,v 1.1 2004/02/03 13:06:24 comdog Exp $

use Test::More tests => 23;

use Mac::PropertyList::Foundation;

########################################################################
# Test the data bits
my $date = Mac::PropertyList::Foundation::date->new();
isa_ok( $date, "Mac::PropertyList::Foundation::date" );

########################################################################
# Test the real bits
my $real = Mac::PropertyList::Foundation::real->new();
isa_ok( $real, "Mac::PropertyList::Foundation::real" );

{
my $value = 3.15;
$string = Mac::PropertyList::Foundation::real->new( $value );
isa_ok( $string, "Mac::PropertyList::Foundation::real" );
is( $string->value, $value );
is( $string->type, 'real' );
is( $string->write, "<real>$value</real>" );
}

########################################################################
# Test the integer bits
my $integer = Mac::PropertyList::Foundation::integer->new();
isa_ok( $integer, "Mac::PropertyList::Foundation::integer" );

{
my $value = 37;
$string = Mac::PropertyList::Foundation::integer->new( $value );
isa_ok( $string, "Mac::PropertyList::Foundation::integer" );
is( $string->value, $value );
is( $string->type, 'integer' );
is( $string->write, "<integer>$value</integer>" );
}

########################################################################
# Test the string bits
my $string = Mac::PropertyList::Foundation::string->new();
isa_ok( $string, "Mac::PropertyList::Foundation::string" );

{
my $value = 'Buster';
$string = Mac::PropertyList::Foundation::string->new( $value );
isa_ok( $string, "Mac::PropertyList::Foundation::string" );
is( $string->value, $value );
is( $string->type, 'string' );
is( $string->write, "<string>$value</string>" );
}

########################################################################
# Test the data bits
my $data = Mac::PropertyList::Foundation::data->new();
isa_ok( $data, "Mac::PropertyList::Foundation::data" );


########################################################################
# Test the boolean bits
my $true = Mac::PropertyList::Foundation::true->new;
isa_ok( $true, "Mac::PropertyList::Foundation::true" );
is( $true->value, 'true' );
is( $true->write, '<true/>' );

my $false = Mac::PropertyList::Foundation::false->new;
isa_ok( $false, "Mac::PropertyList::Foundation::false" );
is( $false->value, 'false' );
is( $false->write, '<false/>' );


