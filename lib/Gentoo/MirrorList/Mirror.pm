use strict;
use warnings;

package Gentoo::MirrorList::Mirror;

# ABSTRACT: An objective representation of a single Gentoo mirror

use Moose;
use namespace::autoclean;

my %bools = ();
my %strs  = ();

=attr C<country>

=attr C<countryname>

=attr C<region>

=attr C<mirrorname>

=attr C<uri>

=attr C<proto>

=cut

for (qw(  country countryname region mirrorname uri proto )) {
  has $_ => (
    isa      => 'Str',
    is       => 'ro',
    required => 1,
    traits   => [qw( String )],
    handles  => { $_ . '_match' => 'match' },
  );
  $strs{$_} = 1;
}

=attr C<ipv4>

=attr C<ipv6>

=attr C<partial>

=cut

for (qw( ipv4 ipv6 partial )) {
  has $_ => ( isa => 'Bool', is => 'ro', required => 1, );
  $bools{$_} = 1;
}

=method C<country_match>

  ->country_match( 'str' )
  ->country_match(qr/str/)

=method C<countryname_match>

  ->countryname_match( 'str' )
  ->countryname_match(qr/str/)

=method C<region_match>

  ->region_match( 'str' )
  ->region_match(qr/str/)

=method C<mirrorname_match>

  ->mirrorname_match( 'str' )
  ->mirrornamename_match(qr/str/)

=method C<uri_match>

  ->uri_match( 'str' )
  ->uri_match(qr/str/)

=method C<proto_match>

  ->proto_match( 'str' )
  ->proto_match(qr/str/)

=cut

around BUILDARGS => sub {
  my ( $orig, $class, @args ) = @_;
  for my $argno ( 0 .. $#args ) {
    last if not exists $args[ $argno + 1 ];
    for my $bool ( keys %bools ) {
      if ( $args[$argno] eq $bool ) {

        if ( 'Y' eq uc $args[ $argno + 1 ] ) {
          $args[ $argno + 1 ] = 1;
        }
        if ( 'N' eq uc $args[ $argno + 1 ] ) {
          $args[ $argno + 1 ] = q();
        }
      }
    }
  }
  return $class->$orig(@args);
};

=method C<property_match>

A Magic Method that matches given properties

  ->property_match( 'mirrorname', 'foo')    # mirrorname eq foo
  ->property_match( 'mirrorname', qr/foo/ ) # mirrorname =~ qr/foo/
  ->property_match( 'ipv4', 1 )             # not ( 0 xor ipv4 )
  ->property_match( 'ipv6', 0 )             # not ( 0 xor ipv6 )

=cut

sub property_match {
  my ( $self, $property, $value ) = @_;
  if ( not exists $bools{$property} and not exists $strs{$property} ) {
    require Carp;
    Carp::confess("Cannot match with property `$property`");
  }
  if ( exists $bools{$property} ) {
    my $sub = $self->can($property);

    # Xand
    # 0 & 0 ==> 1
    # 1 & 0 ==> 0
    # 0 & 1 ==> 0
    # 1 & 1 ==> 1
    # Xand == !Xor
    return ( not( $value xor $self->$property() ) );
  }
  if ( exists $strs{$property} ) {
    if ( ref $value ne 'REGEX' ) {
      my $sub = $self->can($property);

      return $self->$sub() eq $value;
    }
    else {
      my $sub = $self->can( $property . '_match' );
      return $self->$sub($value);
    }
  }
}

=method C<file>

Provide a file uri for file.

  ->file('distfiles/QuuxFoo.bar.tar.gz') # http://your.mirror.here/path/to/distfiles/QuuxFoo.bar.tar.gz

=cut

sub file {
  my ( $self, $file ) = @_;
  my $uri = $self->uri;
  $file =~ s{^\/}{};
  $uri =~ s{\/$}{};

  return sprintf '%s/%s', $uri, $file;
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

