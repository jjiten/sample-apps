#!perl

BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}

# This file was automatically generated by Dist::Zilla::Plugin::Test::TidyAll

use Test::Code::TidyAll 0.24;
use Test::More 0.88;

tidyall_ok();

done_testing();
