use strict;
use warnings;

package Gentoo::MirrorList;

# ABSTRACT: A programmatic way to access Gentoo.org Mirror Metadata

use Moose;
use App::Cache;
use namespace::autoclean;
use Gentoo::MirrorList::Mirror;

=head1 SYNOPSIS

  my @mirrors = Gentoo::MirrorList->region('North America')->country('CA')->ipv4->all;
  my @mirrors = Gentoo::MirrorList->region('North America')->ipv4->random(3);
  my $mirror = Gentoo::MirrorList->region('Australia')->ipv4->random();
  my @all_names = Gentoo::MirrorList->mirrorname_list
  my @australian_names = Gentoo::MirrorList->country('AU')->mirrorname_list;


=cut

=head1 DESCRIPTION

This module will download the most up-to-date copy of L<http://www.gentoo.org/main/en/mirrors3.xml> and parse it into
an array of L<Gentoo::MirrorList::Mirror> which you can then filter down progressively using the methods
defined below to find, via code, any mirror that meets a given criteria.

For efficiency, this module uses L<App::Cache> to cache both the mirror list and the parsed representation of that list,
and the data files are stored in ~/.gentoo_mirrorlist/cache/

=cut

=head1 METHODS

=head2 FILTER METHODS

All of the following self-filter the data set they are on.

  my $x = Gentoo::MirrorList->FILTER
  my $y = Gentoo::MirrorList->new()
  my $z = $y->FILTER

x and y will be the same. y and z will be the same object.

=head2 TERMINATOR LIST METHODS

If called directly on L<Gentoo::MirrorList> will return all data possible.

If called on an object that has been filtered, only shows the data that is applicable.

=head2 MIRROR LIST METHODS

The following methods will return one or more L<Gentoo::MirrorList::Mirror> objects,

They can be called directly on L<Gentoo::MirrorList> or on filtered objects.

On filtered objects, the filtration that has been performed affects the output.

=cut

=p_attr _cache

=cut

has _cache => (
  isa     => 'App::Cache',
  is      => 'ro',
  lazy    => 1,
  default => sub {
    return App::Cache->new( { ttl => 60 * 60, application => __PACKAGE__ } );
  },
);

=p_attr _data

=cut

has '_data' => (
  isa        => 'ArrayRef[ Gentoo::MirrorList::Mirror ]',
  is         => 'rw',
  lazy_build => 1,
  traits     => [qw[ Array ]],
  handles    => { _data_filter => 'grep', _data_iterate => 'map', _data_count => 'count', _data_shuffle => 'shuffle' },
);

=p_attr _xml

=cut

has '_xml' => (
  isa        => 'Str',
  is         => 'ro',
  lazy_build => 1,
);

=p_method _normalise_mirrorgroup

=cut

sub _normalise_mirrorgroup {
  my ( $self, $mirrorgroup ) = @_;
  if ( exists $mirrorgroup->{mirror}->{uri} and exists $mirrorgroup->{mirror}->{name} ) {
    $mirrorgroup->{mirror} = { $mirrorgroup->{mirror}->{name} => { uri => $mirrorgroup->{mirror}->{uri} } };
  }
  for my $name ( keys %{ $mirrorgroup->{mirror} } ) {
    if ( ref $mirrorgroup->{mirror}->{$name}->{uri} eq 'HASH' ) {
      $mirrorgroup->{mirror}->{$name}->{uri} = [ $mirrorgroup->{mirror}->{$name}->{uri} ];
    }
  }
  return $mirrorgroup;
}

=p_method __build_mirrorgroup

=cut

sub __build_mirrorgroup {
  my ( $self, $mirrorgroup ) = @_;
  $mirrorgroup = $self->_normalise_mirrorgroup($mirrorgroup);
  my @mirrors = ();
  my %data    = (
    country     => $mirrorgroup->{country},
    countryname => $mirrorgroup->{countryname},
    region      => $mirrorgroup->{region},
  );
  for my $mirrorname ( keys %{ $mirrorgroup->{mirror} } ) {

    for my $uri ( @{ $mirrorgroup->{mirror}->{$mirrorname}->{uri} } ) {
      my $i = Gentoo::MirrorList::Mirror->new(
        %data,
        mirrorname => $mirrorname,
        uri        => $uri->{content},
        proto      => $uri->{protocol},
        ipv4       => $uri->{ipv4},
        ipv6       => $uri->{ipv6},
        partial    => $uri->{partial},
      );
      push @mirrors, $i;

    }
  }
  return (@mirrors);
}

=p_method _build_data

=cut

sub _build__data {
  my ($self) = @_;

  my $r = $self->_cache->get('data');
  if ($r) {
    return $r;
  }
  my $content = $self->_xml;
  require XML::Simple;
  my $structure = XML::Simple::xml_in($content);

  my @rows;
  for ( @{ $structure->{'mirrorgroup'} } ) {
    push @rows, $self->__build_mirrorgroup($_);
  }

  $self->_cache->set( 'data', \@rows );
  return \@rows;
}

=p_method _build__xml

=cut

sub _build__xml {
  my ($self) = @_;
  return $self->_cache->get_url('http://www.gentoo.org/main/en/mirrors3.xml');
}

=p_method _filter

=cut

sub _filter {
  my ( $self, $property, $param ) = @_;
  $self->_data(
    [
      $self->_data_filter(
        sub {
          return $_->property_match( $property, $param );
        }
      )
    ]
  );
  return $self;
}

=p_method _unfilter

=cut

sub _unfilter {
  my ( $self, $property, $param ) = @_;
  $self->_data(
    [
      $self->s_filter(
        sub {
          return not $_->property_match( $property, $param );
        }
      )
    ]
  );
  return $self;
}

=filter country

  ..->country( 'AU' )->..
  ..->country( qr/AU/ )->..

See also L</country_list>

=filter countryname

  ..->countryname( 'Australia' )->..
  ..->countryname( qr/Aus/ )->..

See also L</countryname_list>

=filter region

  ..->region('North America')->..
  ..->region(qr/America/)->..

See also L</region_list>

=filter mirrorname

  ..->mirrorname(qr/^a/i)->..

See also L</mirrorname_list>

=filter uri

  ..->uri(qr/gentoo/)->..

See also L</uri_list>

=filter proto

  ..->proto('http')->..
  ..->proto(qr/^.*tp$/)->..

See also L</proto_list>

=filter ipv4

  ..->ipv4( 1 )->..
  ..->ipv4( 0 )->..

=filter ipv6

  ..->ipv6( 1 )->..
  ..->ipv6( 0 )->..

=filter partial

  ..->partial( 1 )->..
  ..->partial( 0 )->..

=cut

for my $property (qw( country countryname region mirrorname uri proto ipv4 ipv6 partial )) {
  __PACKAGE__->meta->add_method(
    $property => sub {
      my ( $self, $param ) = @_;
      $self = $self->new() unless ref $self;
      $self->_filter( $property, $param );
      return $self;
    }
  );
}

=filter exclude_country

  ..->exclude_country(qr/^K/i)->..
  ..->exclude_country('AU')->..

See also L</country_list>

=filter exclude_countryname

  ..->exclude_countryname(qr/America/i)->..
  ..->exclude_countryname('Australia')->..

See also L</countryname_list>

=filter exclude_region

  ..->exclude_region(qr/Foo/)->..
  ..->exclude_region('Foo')->..

See also L</region_list>

=filter exclude_mirrorname

  ..->exclude_mirrorname(qr/Bad/)->..
  ..->exclude_mirrorname('Bad')->..

See also L</mirrorname_list>

=filter exclude_uri

  ..->exclude_uri(qr/Bad\.ip/)->..
  ..->exclude_uri('Bad.ip')->..

See also L</uri_list>

=filter exclude_proto

  ..->exclude_proto(qr/sync/)->..
  ..->exclude_proto('rsync')->..

See also L</proto_list>

=cut

for my $property (qw( country countryname region mirrorname uri proto )) {
  __PACKAGE__->meta->add_method(
    'exclude_' . $property => sub {
      my ( $self, $param ) = @_;
      $self = $self->new() unless ref $self;
      $self->_unfilter( $property, $param );
      return $self;
    }
  );
}

=filter is_ipv4

  ..->is_ipv4->..

=filter not_ipv4

  ..->not_ipv4->..

=filter is_ipv6

  ..->is_ipv6->..

=filter not_ipv6

  ..->not_ipv6->..

=filter is_partial

  ..->is_partial->..

=filter not_partial

  ..->not_partial->..

=cut

for my $property (qw( ipv4 ipv6 partial )) {
  __PACKAGE__->meta->add_method(
    'is_' . $property => sub {
      my ( $self, $param ) = @_;
      $self = $self->new() unless ref $self;
      $self->_filter( $property, 1 );
      return $self;
    }
  );
  __PACKAGE__->meta->add_method(
    'not_' . $property => sub {
      my ( $self, $param ) = @_;
      $self = $self->new() unless ref $self;
      $self->_filter( $property, 1 );
      return $self;
    }
  );
}

=terminator country_list

  my ( @foo ) = ...->country_list

=terminator countryname_list

  my ( @foo ) = ...->countryname_list

=terminator region_list

  my ( @foo ) = ...->region_list

=terminator mirrorname_list

  my ( @foo ) = ...->mirrorname_list

=terminator uri_list

  my ( @foo ) = ...->uri_list

=terminator proto_list

  my ( @foo ) = ...->proto_list

=cut

for my $property (qw( country countryname region mirrorname uri proto )) {
  __PACKAGE__->meta->add_method(
    $property . '_list' => sub {
      my ($self) = @_;
      $self = $self->new() unless ref $self;
      my %v      = ();
      my $method = Gentoo::MirrorList::Mirror->can($property);
      $self->_data_iterate( sub { $v{ $_->$method() } = 1 } );
      return [ sort keys %v ];
    }
  );
}

=mirrorlist random

  my ( $mirror )  = ...->random()
  my ( @mirrors ) = ...->random( 10 );

=cut

sub random {
  my ( $self, $amt ) = @_;
  $self = $self->new() unless ref $self;
  $amt  = 1            unless defined $amt;
  my (@out) = $self->_data_shuffle;
  if ( $amt > ( $self->_data_count ) ) {
    push @out, map { $self->_data_shuffle } 0 .. int( ( $amt - $self->_data_count ) / $self->_data_count + 1 );
  }
  return $out[0] if $amt == 1;
  return @out[ 0 .. $amt - 1 ];
}

=mirrorlist all

returns all Mirrors in the current filtration.

There is no explicit sort order, but it will likely resemble parse order

=cut

sub all {
  my ($self) = @_;
  $self = $self->new() unless ref $self;
  return @{ $self->_data };
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

