
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "FindBin" => 0,
    "Module::Build" => "0.3601",
    "Test::More" => "0.88"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "A programmatic way to access Gentoo.org Mirror Metadata",
  "dist_author" => [
    "Kent Fredric <kentnl\@cpan.org>"
  ],
  "dist_name" => "Gentoo-MirrorList",
  "dist_version" => "1.0.1",
  "license" => "perl",
  "module_name" => "Gentoo::MirrorList",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "App::Cache" => 0,
    "Carp" => 0,
    "Moose" => 0,
    "XML::Simple" => 0,
    "namespace::autoclean" => 0,
    "perl" => "5.10.0",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
