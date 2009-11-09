
use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
  module_name   => 'Gentoo::MirrorList',
  license       => 'perl',
  dist_abstract => "A\ programmatic\ way\ to\ access\ Gentoo\.org\ Mirror\ Metadata",
  dist_name     => "Gentoo\-MirrorList",
  dist_author   => [
"Kent\ Fredric\ \<kentnl\@cpan\.org\>",
  ],
  requires      => {

  },
  script_files => [ qw() ],
);

$build->create_build_script;
