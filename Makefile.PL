
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'Gentoo-MirrorList',
  NAME      => 'Gentoo::MirrorList',
  AUTHOR    => "Kent\ Fredric\ \<kentnl\@cpan\.org\>",
  ABSTRACT  => "A\ programmatic\ way\ to\ access\ Gentoo\.org\ Mirror\ Metadata",
  VERSION   => '0.01000101',
  EXE_FILES => [ qw() ],
  (eval { ExtUtils::MakeMaker->VERSION(6.31) } ? (LICENSE => 'perl') : ()),
  PREREQ_PM    => {

  },
  test => {TESTS => 't/*.t'}
);

