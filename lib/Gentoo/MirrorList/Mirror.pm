package Gentoo::MirrorList::Mirror;

# ABSTRACT: An objective representation of a single gentoo mirror

use strict;
use warnings;
use Moose;
use namespace::autoclean;

my %bools = ();
my %strs  = ();

for (qw(  country countryname region mirrorname uri proto )) {
  has $_ => (
    isa      => 'Str',
    is       => 'ro',
    required => 1,
    traits   => [qw( String )],
    handles  => { $_ . '_match' => 'match' }
  );
  $strs{$_} = 1;
}
for (qw( ipv4 ipv6 partial )) {
  has $_ => ( isa => 'Bool', is => 'ro', required => 1 );
  $bools{$_} = 1;
}

around BUILDARGS => sub {
  my ( $orig, $class, @args ) = @_;
  for my $argno ( 0 .. $#args ) {
    last if not exists $args[ $argno + 1 ];
    for my $bool ( keys %bools ) {
      if ( $args[$argno] eq $bool ) {

        if ( $args[ $argno + 1 ] =~ /^Y$/i ) {
          $args[ $argno + 1 ] = 1;
        }
        if ( $args[ $argno + 1 ] =~ /^N$/i ) {
          $args[ $argno + 1 ] = '';
        }
      }
    }
  }
  return $class->$orig(@args);
};

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
    my $sub = $self->can( $property . "_match" );
    return $self->$sub($value);
  }
}

__PACKAGE__->meta->make_immutable;

1;

