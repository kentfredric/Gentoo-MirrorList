
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'Gentoo-MirrorList',
  NAME      => 'Gentoo::MirrorList',
  AUTHOR    => "Kent\ Fredric\ \<kentnl\@cpan\.org\>",
  ABSTRACT  => "A\ programmatic\ way\ to\ access\ Gentoo\.org\ Mirror\ Metadata",
  VERSION   => '0.01000112',
  EXE_FILES => [ qw() ],
  (eval { ExtUtils::MakeMaker->VERSION(6.31) } ? (LICENSE => 'perl') : ()),
  PREREQ_PM    => {
    "Test::More" => '0.94',
    "namespace::autoclean" => '0.09',
    "XML::Simple" => '2.18',
    "App::Cache" => '0.36',
    "Moose" => '0.92',
  },
  test => {TESTS => 't/*.t'}
);

