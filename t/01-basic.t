
use strict;
use warnings;

use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Path qw(rmtree);
use File::Spec;
use Test::More tests => 2;

my $gpackage =
  abs_path( File::Spec->catdir( dirname(__FILE__), qw(.. bin gpackage) ) );
my $testdir = abs_path( File::Spec->catdir( dirname(__FILE__), 'data' ) );
my $pkgdir  = abs_path( File::Spec->catdir( $testdir,          'gpackage' ) );
my $app1dir = abs_path( File::Spec->catdir( $testdir, 'app', 'app1' ) );
my $app2dir = abs_path( File::Spec->catdir( $testdir, 'app', 'app2' ) );
my $app1pkg = abs_path( File::Spec->catdir( $pkgdir,  'app1' ) );
my $app2pkg = abs_path( File::Spec->catdir( $pkgdir,  'app2' ) );
my $targetdir = abs_path( File::Spec->catdir( $testdir, 'target' ) );

# build_up
#
# Initializes test environment
sub build_up {
}

# tear_down
#
# Cleans up the test environment
sub tear_down {
  rmtree( File::Spec->catdir( $targetdir, 'bin' ) );
  rmtree( File::Spec->catdir( $targetdir, 'lib' ) );
  unlink $app1pkg;
  unlink $app2pkg;
}

sub test_installation {
  my @output = `$gpackage installed 2>&1`;
  is_deeply( \@output, [], 'No packages installed' );

  open( FILE, '>', $app1pkg ) or BAIL_OUT( $app1pkg . ':' . $! );
  print FILE<<APP1END;
\@$targetdir
$app1pkg
APP1END
  close FILE;

  @output = `$gpackage installed 2>&1`;
  is_deeply( \@output, ["app1\n"], 'One package installed' );

  ok( open( FILE, '>', $app2pkg ) ) or BAIL_OUT( $app2pkg . ':' . $! );
  print FILE<<APP1END;
\@$targetdir/bin
$app2pkg/bin
APP1END
  close FILE;

  @output = `$gpackage installed 2>&1`;
  is_deeply( \@output, [ "app1\n", "app2\n" ], 'Two packages installed' );
}

sub test_list {

}

sub test_enable {

}

sub test_disable {

}

# Clean up any test residues
tear_down();

test_installation();

tear_down();

