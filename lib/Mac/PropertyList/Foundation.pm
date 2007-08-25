package Mac::PropertyList::Foundation;

use warnings;
use strict;
use Carp qw/croak carp/;
use File::Temp qw/tempdir tempfile/;
use Foundation;

use vars qw/@EXPORT_OK %EXPORT_TAGS/;

use base qw/Exporter/;

@EXPORT_OK = qw(
    parse_plist 
    parse_plist_fh
    parse_plist_file
    plist_as_string 
    create_from_hash
    create_from_array
);

%EXPORT_TAGS = (
    'all' => \@EXPORT_OK,
);

use version; our $VERSION = qv('0.0.3');

# Other recommended modules (uncomment to use):
#  use IO::Prompt;
#  use Perl6::Export;
#  use Perl6::Slurp;
#  use Perl6::Say;


# Module implementation here


sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my %params = @_;

    my $self = bless {}, $class;

    if ( $params{file} ) {

        return $self->load_file( $params{file} );
    }

    return $self;
}

sub load_file {
    my $plist_file = shift;

    my $self = undef;

    if ( ref($plist_file) ) {
        $self = $plist_file;
        $plist_file = shift;
    }

    croak( "file not found, dumbass." ) unless ( -r $plist_file );

    $self->{plist_file} = $plist_file;

    $self = Mac::PropertyList::Foundation::dict->new(
        dict => NSDictionary->dictionaryWithContentsOfFile_( $plist_file )
    );
}

sub parse_plist {
    my $self = shift;
    my $text = shift;

    if ( !ref($self) ) {
        $text = $self;
    }

    my $tempdir = tempdir(
        # CLEANUP => 1
    );

    warn( "Temp Dir: $tempdir" );

    my ( $fh, $tempfile ) = tempfile( DIR => $tempdir );

    warn( "Temp File: $tempfile" );

    $fh->print( $text );

    $fh->close;

    return $self = load_file( $tempfile );
}

1;

package Mac::PropertyList::Foundation::Util;

use base qw(Exporter);
use vars qw/@EXPORT_OK/;

@EXPORT_OK = qw/perlValue/;

sub perlValue {
    my $object = shift;
    # warn( "Here I am: ", sprintf( '%s %s %d', caller ) );
    # print "ref: ", ref($object), ": $object ( ", $$object, ")\n";
    # print "caller: ", join( ' ', caller ), "\n";
    # print "caller: ", join( ' ', (caller(1))[0,1,2] ), "\n";
    return $object->description()->UTF8String();
}

1;

package Mac::PropertyList::Foundation::dict;

use strict;
use Carp qw(croak carp);
use Foundation;
use Data::Dumper;

use overload '""' => \&as_string;

Mac::PropertyList::Foundation::Util->import( qw/perlValue/ );

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my %params = @_;

    my $self = {};

    if ( $params{dict} ) {

        croak(
            "dict paramter is not NSCFDictionary (", ref($params{dict}), ")"
        ) unless ( ref($params{dict}) && ref($params{dict}) eq 'NSCFDictionary' );

        $self->{plist} = $params{dict};
    }
    else {
        die( "argument must be specified." );
    }

    return bless $self, $class;
}

sub get {

    my $self = shift;
    my $key = shift;

    # print "Getting: $key\n";
    if (
        defined( $self->{cache}->{"$key"} )
    ) {
        return $self->{cache}->{"$key"}
    }

    my $val = $self->{plist}->objectForKey_( "$key" );

    if ( ref($val) eq 'NSCFDictionary' ) {
        return $self->{cache}->{"$key"} = Mac::PropertyList::Foundation::dict->new(
            dict => $val,
        );
    }
    elsif ( ref($val) eq 'NSCFArray' ) {
        return $self->{cache}->{"$key"} = Mac::PropertyList::Foundation::array->new(
            array => $val,
        );
    }

    if ( ref($val) eq 'SCALAR' ) {
        carp( "Somehow wound up with a scalar ref from objectForKey: $$val" );
        return;
    }

    return $self->{cache}->{"$key"} = Mac::PropertyList::Foundation::Value->new( $val );
}

sub set {
    die( __PACKAGE__, ": set not implemented." );
}

sub delete {
    die( __PACKAGE__, ": delete not implemented." );
}

sub exists {
    my $self = shift;
    my $key = shift;

    my $tmp = $self->{plist}->objectForKey_( "$key" );

    return 1 == 0 if (
        !defined( $tmp )
        || !defined( $$tmp )
        || !ref($$tmp)
    );

    return 1 == 1;
}

## in scalar context, return count() to save all of the execution!

sub keys {
    my $self = shift;

    return map {
        Mac::PropertyList::Foundation::Value->new( $_ )
    } Mac::PropertyList::Foundation::array->new(
        array => $self->{plist}->allKeys(),
    )->entries;
}

sub next_key {
    my $self = shift;

    $self->{key_enum} = $self->{plist}->keyEnumerator() unless ( $self->{key_enum} );

    my $val = $self->{key_enum}->nextObject;

    return unless ( $$val );

    return Mac::PropertyList::Foundation::Value->new($val);
}

sub count {
    my $self = shift;

    return $self->{plist}->count;
}

sub as_string {
    my $self = shift;

    sprintf( '%s (%d keys)', ref($self), $self->count );
}

1;

package Mac::PropertyList::Foundation::array;

use strict;
use Carp qw(croak carp);
use Foundation;
use Data::Dumper;

use overload '""' => \&as_string;

Mac::PropertyList::Foundation::Util->import( qw/perlValue/ );

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my %params = @_;

    my $self = {};

    if ( $params{array} ) {

        croak(
            "array paramter is not NSCFArray (", ref($params{array}), ")"
        ) unless ( ref($params{array}) && ref($params{array}) eq 'NSCFArray' );

        $self->{plist} = $params{array};
    }

    return bless $self, $class;
}

sub get {

    my $self = shift;
    my $index = shift;

    # print "Getting: $key\n";

    my $val = $self->{plist}->objectAtIndex_( $index );

    if ( ref($val) eq 'NSCFDictionary' ) {
        return new Mac::PropertyList::Foundation::dict(
            dict => $val,
        );
    }
    elsif ( ref($val) eq 'NSCFArray' ) {
        return new Mac::PropertyList::Foundation::array(
            array => $val,
        );
    }

    if ( ref($val) eq 'SCALAR' ) {
        carp( "Somehow wound up with a scalar ref from objectAtIndex $$val" );
        return;
    }

    return Mac::PropertyList::Foundation::Value->new( $val );
}

## In a scalar context, return count() to avoid all of the processing..
## Also change variable name. :)

sub entries {
    my $self = shift;

    my @keys = ();

    my $enum = $self->{plist}->objectEnumerator();

    while ( my $val = $enum->nextObject() ) {
        last unless ( $$val );
        push @keys, $val;
    }

    return @keys;
}

sub next_entry {
    my $self = shift;

    $self->{enum} = $self->{plist}->objectEnumerator() unless ( $self->{enum} );

    my $val = $self->{enum}->nextObject;

    return unless ( $$val );

    if ( ref($val) eq 'NSCFDictionary' ) {
        return Mac::PropertyList::Foundation::dict->new( dict => $val, );
    }
    elsif ( ref($val) eq 'NSCFArray' ) {
        return Mac::PropertyList::Foundation::array->new( array => $val, );
    }

    return Mac::PropertyList::Foundation::Value->new($val);
}

sub count {
    my $self = shift;

    return $self->{plist} ? $self->{plist}->count : 0;
}

sub as_string {
    my $self = shift;

    sprintf( '%s (%d entries)', ref($self), $self->count );
}

1;

package Mac::PropertyList::Foundation::Value;

use strict;
use Carp qw(croak carp);
use Foundation;
use Data::Dumper;

use overload
    '0+' => \&num_value;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $val = shift;

    if ( ref($val) eq 'NSCFString' ) {
        return Mac::PropertyList::Foundation::String->new( $val );
    }
    elsif ( ref($val) eq 'NSCFNumber' ) {
        return Mac::PropertyList::Foundation::Number->new( $val );
    }
    elsif ( ref($val) eq 'NSCFDate' ) {
        return Mac::PropertyList::Foundation::Date->new( $val );
    }
    elsif ( ref($val) eq 'NSCFData' ) {
        return Mac::PropertyList::Foundation::Data->new( $val );
    }
    elsif ( ref($val) eq 'NSCFBoolean' ) {
        return Mac::PropertyList::Foundation::Bool->new( $val );
    }
    else {
        croak( "Unknown value passed in: ", ref( $val ) );
    }

    return;

}

sub num_value {
    my $self = shift;

    return $self->{num_value} if ( defined( $self->{num_value} ) );

    return $self->{num_value} = $self->{value}->doubleValue();
}

1;

package Mac::PropertyList::Foundation::String;

use strict;
use Carp qw(croak carp);
use Foundation;
use Data::Dumper;
use base qw/Mac::PropertyList::Foundation::Value/;
use overload '""' => \&str_value;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $val = shift;

    return bless { value => $val }, $class;
}

sub str_value {
    my $self = shift;

    return $self->{str_value} if ( defined( $self->{str_value} ) );

    return $self->{str_value} = $self->{value}->UTF8String;
}

1;

package Mac::PropertyList::Foundation::Number;

use strict;
use Carp qw(croak carp);
use Foundation;
use Data::Dumper;
use base qw/Mac::PropertyList::Foundation::Value/;

use overload '""' => \&str_value;

Mac::PropertyList::Foundation::Util->import( qw/perlValue/ );

sub str_value {
    my $self = shift;

    return $self->{str_value} if ( defined( $self->{str_value} ) );

    return $self->{str_value} = Mac::PropertyList::Foundation::String->new($self->{value}->stringValue);
}

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $val = shift;

    return bless { value => $val }, $class;
}

1;

package Mac::PropertyList::Foundation::Date;

use strict;
use Carp qw(croak carp);
use Foundation;
use Data::Dumper;
use base qw/Mac::PropertyList::Foundation::Value/;

use overload
    '+0' => \&num_value,
    '""' => \&str_value;

Mac::PropertyList::Foundation::Util->import( qw/perlValue/ );

sub num_value {
    my $self = shift;

    return $self->{num_value} if ( defined( $self->{num_value} ) );

    return $self->{num_value} = $self->{value}->NSTimeIntervalSince1970();
}

sub str_value {
    my $self = shift;

    return $self->{str_value} if ( defined( $self->{str_value} ) );

    return $self->{str_value} = $self->{value}->description->UTF8String;
}

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $val = shift;

    return bless { value => $val }, $class;
}

1;

package Mac::PropertyList::Foundation::Data;

use strict;
use Carp qw(croak carp);
use Foundation;
use Data::Dumper;
use base qw/Mac::PropertyList::Foundation::Value/;

use overload
    '""' => \&str_value,
    '0+' => \&str_value;

Mac::PropertyList::Foundation::Util->import( qw/perlValue/ );

sub str_value {
    my $self = shift;

    return $self->{str_value} if ( defined( $self->{str_value} ) );

    return $self->{str_value} = ref( $self ); # pack "c*", $self->{value}->bytes;
}

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $val = shift;

    return bless { value => $val }, $class;
}

1;

package Mac::PropertyList::Foundation::Bool;

use strict;
use Carp qw(croak carp);
use Foundation;
use Data::Dumper;
use base qw/Mac::PropertyList::Foundation::Value/;

use overload
    'bool' => \&bool_value,
    '""' => \&num_value,
    '""' => \&str_value;

Mac::PropertyList::Foundation::Util->import( qw/perlValue/ );

sub str_value {
    my $self = shift;

    return $self->{str_value} if ( defined( $self->{str_value} ) );

    return $self->{str_value} = $self->{value}->boolValue ? '1' : '0';
}

sub num_value {
    my $self = shift;

    return $self->{num_value} if ( defined( $self->{num_value} ) );

    return $self->{num_value} = $self->{value}->boolValue ? 1 : 0;
}

sub bool_value {
    my $self = shift;

    return $self->{bool_value} if ( defined( $self->{bool_value} ) );

    return $self->{bool_value} = $self->{value}->boolValue ? 1 == 1 : 0 == 1;
}

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $val = shift;

    return bless { value => $val }, $class;
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Mac::PropertyList::Foundation - [One line description of module's purpose here]


=head1 VERSION

This document describes Mac::PropertyList::Foundation version 0.0.1


=head1 SYNOPSIS

    use Mac::PropertyList::Foundation;

=for author to fill in:
    Brief code example(s) here showing commonest usage(s).
    This section will be as far as many users bother reading
    so make it as educational and exeplary as possible.
  
  
=head1 DESCRIPTION

=for author to fill in:
    Write a full description of the module and its features here.
    Use subsections (=head2, =head3) as appropriate.


=head1 INTERFACE 

=for author to fill in:
    Write a separate section listing the public components of the modules
    interface. These normally consist of either subroutines that may be
    exported, or methods that may be called on objects belonging to the
    classes provided by the module.


=head1 DIAGNOSTICS

=for author to fill in:
    List every single error and warning message that the module can
    generate (even the ones that will "never happen"), with a full
    explanation of each problem, one or more likely causes, and any
    suggested remedies.

=over

=item C<< Error message here, perhaps with %s placeholders >>

[Description of error here]

=item C<< Another error message here >>

[Description of error here]

[Et cetera, et cetera]

=back


=head1 CONFIGURATION AND ENVIRONMENT

=for author to fill in:
    A full explanation of any configuration system(s) used by the
    module, including the names and locations of any configuration
    files, and the meaning of any environment variables or properties
    that can be set. These descriptions must also include details of any
    configuration language used.
  
Mac::PropertyList::Foundation requires no configuration files or environment variables.


=head1 DEPENDENCIES

=for author to fill in:
    A list of all the other modules that this module relies upon,
    including any restrictions on versions, and an indication whether
    the module is part of the standard Perl distribution, part of the
    module's distribution, or must be installed separately. ]

None.


=head1 INCOMPATIBILITIES

=for author to fill in:
    A list of any modules that this module cannot be used in conjunction
    with. This may be due to name conflicts in the interface, or
    competition for system or program resources, or due to internal
    limitations of Perl (for example, many modules that use source code
    filters are mutually incompatible).

None reported.


=head1 BUGS AND LIMITATIONS

=for author to fill in:
    A list of known problems with the module, together with some
    indication Whether they are likely to be fixed in an upcoming
    release. Also a list of restrictions on the features the module
    does provide: data types that cannot be handled, performance issues
    and the circumstances in which they may arise, practical
    limitations on the size of data sets, special cases that are not
    (yet) handled, etc.

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-mac-propertylist-foundation@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Jonathan J. Miner  C<< <cpan@jjminer.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Jonathan J. Miner C<< <cpan@jjminer.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
