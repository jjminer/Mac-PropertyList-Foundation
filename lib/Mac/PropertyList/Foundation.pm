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

    # Hack.  Need to guess what it is because there seems to be no good way to
    # tell..

    my $data = NSDictionary->dictionaryWithContentsOfFile_( $plist_file );

    if ( ref( $data ) eq 'NSCFDictionary' ) {
        return $self = Mac::PropertyList::Foundation::dict->new(
            dict => $data
        );
    }

    $data = NSArray->arrayWithContentsOfFile_( $plist_file );

    if ( ref( $data ) eq 'NSCFArray' ) {
        return $self = Mac::PropertyList::Foundation::array->new(
            array => $data
        );
    }

    croak( "Could not load file '$plist_file'" );

    return undef;

}

sub _get_tmp_file {
    my $tempdir = tempdir(
        CLEANUP => 1
    );

    my ( $fh, $tempfile ) = tempfile( DIR => $tempdir );

    return $fh, $tempfile
}

sub parse_plist {
    my $self = shift;
    my $text = shift;

    if ( !ref($self) ) {
        $text = $self;
    }

    my ( $fh, $tempfile ) = _get_tmp_file();

    $fh->print( $text );

    # warn( "Creating Plist file ($tempfile) from:\n$text\n" );

    $fh->close;

    return $self = load_file( $tempfile );
}

sub parse_plist_fh {
    my $self = shift;
    my $fh_in = shift;

    if ( !ref($self) ) {
        $fh_in = $self;
    }

    my ( $fh, $tempfile ) = _get_tmp_file();

    # inefficient, except when the file is large..
    $fh->print( $_ ) while ( <$fh_in> );


    # warn( "Creating Plist file ($tempfile) from:\n$text\n" );

    $fh->close;

    return $self = load_file( $tempfile );
}

sub parse_plist_file {
    my $self = shift;
    my $file = shift;

    if ( !ref($self) ) {
        $file = $self;
    }

    return $self = load_file( $file );
}

sub plist_as_string {
    croak( 'plist_as_string is not defined yet...  whoops.' );
}

sub create_from_hash {
    croak( 'create_from_hash is not defined yet...  whoops.' );
}

sub create_from_array {
    croak( 'create_from_array is not defined yet...  whoops.' );
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


package Mac::PropertyList::Foundation::Item;

use strict;
use Carp qw(croak carp);
use Foundation;
use Data::Dumper;

Mac::PropertyList::Foundation::Util->import( qw/perlValue/ );

sub type { 
    my $self = shift;

    if ( ref($self) eq 'Mac::PropertyList::Foundation::dict' ) {
        return 'dict';
    } elsif ( ref($self) eq 'Mac::PropertyList::Foundation::array' ) {
        return 'array';
    }
    
};

sub value {
    my $self = shift;
    carp( 'Value: ', ref($self), wantarray ? ' wanting array ' : ' not wanting array' );
    return wantarray ? $self->_value : $self;
}

sub _value {
    croak( '_value not defined in', __PACKAGE__ );
}

1;

package Mac::PropertyList::Foundation::dict;

use strict;
use Carp qw(croak carp);
use Foundation;
use Data::Dumper;
use base qw/Mac::PropertyList::Foundation::Item/;

use overload '""' => \&as_string;

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
=for some_other_time
    # Not sure what to do here...
    else {
        carp( "argument must be specified." );
    }
=cut

    return bless $self, $class;
}

sub value {
    my $self = shift;
    my $item = shift;
    return $self->get( $item );
}

sub get {
    ### Caching removed because it creates a "Attempt to free unreferenced scalar" error

    my $self = shift;
    my $key = shift;

    # carp "Getting: $key\n";
=for stupid_caching
    if (
        defined( $self->{cache}->{"$key"} )
    ) {
        carp "Returning ", $self->{cache}->{"$key"}, " for $key\n";
        return $self->{cache}->{"$key"}
    }
=cut

    my $val = $self->{plist}->objectForKey_( "$key" );

    # carp( 'get(', "$key", '): ', ref($val), " ($val)($$val)" );

    if ( ref($val) eq 'NSCFDictionary' ) {
=for stupid_caching
        return $self->{cache}->{"$key"} = Mac::PropertyList::Foundation::dict->new(
            dict => $val,
        );
=cut
        return Mac::PropertyList::Foundation::dict->new(
            dict => $val,
        );
    }
    elsif ( ref($val) eq 'NSCFArray' ) {
=for stupid_caching
        return $self->{cache}->{"$key"} = Mac::PropertyList::Foundation::array->new(
            array => $val,
        );
=cut
        return Mac::PropertyList::Foundation::array->new(
            array => $val,
        );
    }

    if ( ref($val) eq 'SCALAR' ) {
        # Aha... This appears to be the 'not found' case
        if ( $$val eq '0' ) {
            return 0;
        }
        carp( "Somehow wound up with a scalar ref from objectForKey: $$val" );
        return;
    }

=for stupid_caching
    return $self->{cache}->{"$key"} = Mac::PropertyList::Foundation::Value->new( $val );
=cut
    return Mac::PropertyList::Foundation::Value->new( $val );
}

sub set {
    croak( __PACKAGE__, ": set not implemented." );
}

sub delete {
    croak( __PACKAGE__, ": delete not implemented." );
}

sub exists {
    my $self = shift;
    my $key = shift;

    my $tmp = $self->get( $key );

    # carp( 'exists: ', $tmp, ' - ', ref($tmp) );

    # for some reason the Mac::PropertyList tests expect this to return 0..  I
    # would expect it to return boolean 0 == 1..
    return 0 unless (
        defined($tmp) && ref($tmp)
    );

    return 1 == 1;

}

sub as_basic_data {
    my $self = shift;

    return { map {
        $_->can( 'as_basic_data' ) ? $_->as_basic_data : undef => $self->get( $_ )->as_basic_data
    } $self->keys }
}# in scalar context, return count() to save all of the execution!

sub keys {
    my $self = shift;

    return Mac::PropertyList::Foundation::array->new(
        array => $self->{plist}->allKeys(),
    )->entries;
}

sub values {
    my $self = shift;

    return Mac::PropertyList::Foundation::array->new(
        array => $self->{plist}->allValues(),
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

    return defined($self->{plist}) ? $self->{plist}->count : 0;
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
use base qw/Mac::PropertyList::Foundation::Item/;

use overload '""' => \&as_string;

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

sub entries {
    my $self = shift;

    $self->values;
}

sub values {
    my $self = shift;

    return $self->count unless ( wantarray );

    my @values = ();

    my $enum = $self->{plist}->objectEnumerator();

    while ( my $val = $enum->nextObject() ) {
        last unless ( $$val );

        if ( ref($val) eq 'NSCFDictionary' ) {
            push @values, new Mac::PropertyList::Foundation::dict(
                dict => $val,
            );
        }
        elsif ( ref($val) eq 'NSCFArray' ) {
            push @values, new Mac::PropertyList::Foundation::array(
                array => $val,
            );
        }
        else {
            push @values, Mac::PropertyList::Foundation::Value->new($val);
        }
    }

    return @values;
}

sub as_basic_data {
    my $self = shift;

    return [ map {
        $_->can( 'as_basic_data' ) ? $_->as_basic_data : undef
    } $self->values ]
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
    cmp   => \&compare,
    # '<=>' => \&ship,
    # '0+'  => \&num_value,
    # '+'   => \&add,
    # '-'   => \&min,
    # '*'   => \&mult,
    # '/'   => \&div
    ;

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

sub as_basic_data {
    my $self = shift;

    $self->str_value;
}

sub str_value {
    my $self = shift;
    croak( "You must redefine str_value in ", ref($self) );
}

sub binop {
    my $left = shift;
    my $right = shift;
    my $rev = shift;
    my $op = shift;

    if ( $rev ) {
        my $tmp = $left;
        $left = $right;
        $right = $tmp;
    }

    my $lval = ref($left) && $left->can( 'str_value' ) ? $left->str_value : $left;
    my $rval = ref($right) && $right->can( 'str_value' ) ? $right->str_value : $right;

    warn( "binop( $lval, $rval, $rev, $op )" );
    # warn( "lval: ", \$lval );
    # warn( "rval: ", \$rval );

    if ( $op eq '+' ) {
        return $lval + $rval;
    } elsif ( $op eq '-' ) {
        return $lval - $rval;
    } elsif ( $op eq '*' ) {
        return $lval * $rval;
    } elsif ( $op eq '/' ) {
        return $lval / $rval;
    } elsif ( $op eq 'cmp' ) {
        return $lval cmp $rval;
    } elsif ( $op eq '<=>' ) {
        return $lval <=> $rval;
    } else {
        croak( "Unknown op '$op' used on $lval and $rval" );
    }
    return undef;
}

sub compare {
    my $left = shift;
    my $right = shift;

    # warn( "left: ", \$left );
    # warn( "right: ", \$right );

    my $lval = ref($left) && $left->can( 'str_value' ) ? $left->str_value : $left;
    my $rval = ref($right) && $right->can( 'str_value' ) ? $right->str_value : $right;
    # warn( "lval: ", \$lval );
    # warn( "rval: ", \$rval );

    return $lval cmp $rval;


    # return $left->binop( @_, 'cmp' );
    
}

sub ship {
    my $left = shift;

    return $left->binop( @_, '<=>' );
}

sub min {
    my $left = shift;

    return return $left->binop( @_, '-' )
}

sub mult {
    my $left = shift;

    return return $left->binop( @_, '*' )
}

sub div {
    my $left = shift;

    return return $left->binop( @_, '/' )
}

sub add {
    my $left = shift;

    return return $left->binop( @_, '+' )
}

1;

package Mac::PropertyList::Foundation::String;

use strict;
use Carp qw(croak carp);
use Foundation;
use Data::Dumper;
use base qw/Mac::PropertyList::Foundation::Value/;
use overload
    '""' => \&str_value;

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
