
use strict;
use warnings;

use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Path qw(rmtree);
use File::Spec;
use Test::Builder;
use Test::More tests => 34;
use lib dirname(__FILE__);
use Test::Expect::Full;

my $gpackage =
  abs_path( File::Spec->catfile( dirname(__FILE__), qw(.. bin gpackage) ) );
my $testdir = abs_path( File::Spec->catdir( dirname(__FILE__), 'data' ) );
my $app1dir = File::Spec->catdir( $testdir, 'apps', 'app1' );
my $app1common_file = File::Spec->catfile( $app1dir, qw(bin common_file) );
my $app2dir  = File::Spec->catdir( $testdir, 'apps', 'app2' );
my $pkgdir   = File::Spec->catdir( $testdir, 'packages' );
my $database = File::Spec->catdir( $pkgdir,  '.enabled' );
my $app1pkg = File::Spec->catfile( $pkgdir, 'app1' );
my $app2pkg = File::Spec->catfile( $pkgdir, 'app2' );
my $targetdir = File::Spec->catdir( $testdir, 'target' );
my $app1bin1    = File::Spec->catfile( $targetdir, qw(bin bin1) );
my $app2bin2    = File::Spec->catfile( $targetdir, qw(bin bin2) );
my $common_file = File::Spec->catfile( $targetdir, qw(bin common_file) );

$ENV{GPACKAGE_PACKAGE_DIR} = $pkgdir;

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
  unlink $database;
}

# Verify that perl can compile the script
sub test_compile {
  like( `perl -c $gpackage 2>&1`, qr/syntax ok/i, 'script compiles' )
    or BAIL_OUT('script failed to compile');
}

# Verify that the configuration points to the test directory and not to the
# /opy directory
sub test_config {
  my @output = `$gpackage config 2>&1`;
  is_deeply( \@output,
             [ "GPACKAGE_PACKAGE_DIR=$pkgdir\n", "GPACKAGE_DATABASE=$database\n" ],
             'Test environment configured' )
    or BAIL_OUT('Setting up configuration failed');
}

# Installs the package files
#
# Performs the following tests:
#
# * gpackage recognizes installed packages
sub test_installation {
  my @output = `$gpackage list 2>&1`;
  is_deeply( \@output, [], 'No packages installed' );

  open( FILE, '>', $app1pkg )
    or BAIL_OUT( 'Failed to create ' . $app1pkg . ': ' . $! );
  print FILE<<APP1END;
\@$targetdir
$app1dir/
APP1END
  close FILE;

  @output = `$gpackage list 2>&1`;
  is_deeply(
             \@output,
             [
               " Available packages (*=installed)\n",
               "----------------------------------\n",
               "  app1\n"
             ],
             'One package installed'
           );

  open( FILE, '>', $app2pkg )
    or BAIL_OUT( 'Failed to create ' . $app2pkg . ': ' . $! );
  print FILE<<APP2END;
\@$targetdir/bin
$app2dir/bin/
APP2END
  close FILE;

  @output = `$gpackage list 2>&1`;
  is_deeply(
             \@output,
             [
               " Available packages (*=installed)\n",
               "----------------------------------\n",
               "  app1\n",
               "  app2\n"
             ],
             'Two packages installed'
           );
}

# Tests enabling and reenabling of packages
#
# Tests overview:
# * Enabling of packages
# * Enabling an already installed package
# * Reenabling of a package with removed links
#
sub test_enable_reenable {
  my ( $run, @output );

  #
  # Verify that there are no enabled packages
  #
  @output = `$gpackage installed 2>&1`;
  is_deeply( \@output, [], 'No installed packages' );

  ok( !-f $database, 'Database does not exist' ) or BAIL_OUT("Database exists");

  #
  # Enable app1
  #
  @output = `echo "" | $gpackage enable app1 2>&1`;
  is_deeply( \@output, ["Installing 3 elements\n"], 'app1 enabled' );

  unless ( ok( -f $database, 'Database created' ) ) {
    warn `ls -la $pkgdir`;
    BAIL_OUT("No database");
  }

  open( FILE, $database ) or BAIL_OUT( $database . ': ' . $! );
  @output = <FILE>;
  close FILE;
  is_deeply( \@output, ["app1\n"], 'app1 added to database' );
  @output = `$gpackage installed 2>&1`;
  is_deeply( \@output, ["app1\n"], 'app1 installed' );

  unlink $app1bin1;

  #
  # Reenable and abort
  #
  my $gp = Expect->new;

  #$gp->raw_pty(1);
  Expect->spawn( $gpackage, qw(enable app1) );
  $gp->expect( 2, 'app1 is already enabled. Reenable? ' );
  is( $gp->before, '', 'Reenabling question presented 1' );
  $gp->send("no\n");
  $gp->do_soft_close;

  $run = Test::Expect::Full->start( $gpackage, qw(enable app1) );
  $run->expect_is( 'app1 is already enabled. Reenable? ',
                   'Reenabling question presented' );
  $run->send("no\n");
  $run->soft_close;

  ok( !-e $app1bin1, 'Aborting reenabling' );

  $run = Test::Expect::Full->start( $gpackage, qw(enable app1) );
  $run->expect_is( 'app1 is already enabled. Reenable? ',
                   'Reenabling question presented' );
  $run->send("yes\n");
  $run->expect_like( qr#Installing 3 elements.*lib1.*common_file.*or quit.*#s,
                     'Installed files handling question presented' );
  $run->send("skip\n");
  $run->soft_close;

  ok( -l $app1bin1, 'Reenabling ok' );
  like( readlink($app1bin1), qr#apps/app1/bin/bin1$#,
        'Removed link restored by reenable' );
}

# Tests installation of package with clashing files
#
sub test_enable_file_clash {
  my ( $run, @output );
  #
  # Install app2 and abort
  #
  $run = Test::Expect::Full->start( $gpackage, qw(enable app2) );
  $run->expect_like( qr/Installing 2 elements.*${common_file}.*or quit/s,
                     'File clash report' );
  $run->send("quit\n");
  $run->soft_close;

  ok( !-e $app2bin2, 'Package file clash abort' );

  #
  # Install app2 with skip
  #
  $run = Test::Expect::Full->start( $gpackage, qw(enable app2) );
  $run->expect_like( qr/Installing 2 elements.*${common_file}.*or quit/s,
                     'File clash report' );
  $run->send("skip\n");
  $run->soft_close;

  like( readlink($app1bin1), qr/app1/, 'Clashing file not updated' );
  ok( -l $app2bin2, 'Enabling with skip' );

  #
  # Verify that both packages are enabled
  #
  open( FILE, $database ) or BAIL_OUT( $database . ': ' . $! );
  @output = <FILE>;
  close FILE;
  is_deeply( \@output, [ "app1\n", "app2\n" ], 'app2 added to database' );
  @output = `$gpackage installed 2>&1`;
  is_deeply( [ sort @output ], [ "app1\n", "app2\n" ], 'app2 installed' );

}

sub test_disable {
  my ( $run, @output );
  #
  # Disable partially installed package
  #
  $run = Test::Expect::Full->start( $gpackage, qw(disable app2) );
  $run->expect_like(
qr#.*Removing 2 elements.*Warning.*?/common_file.*points to.*${app1common_file}.*Remove anyway.*#is,
    'Unexpected symlink target during disable'
  );
  $run->send("no\n");
  $run->expect_like(
                    qr#${targetdir} was not deleted because it is not empty.*#s,
                    'Target directory not removed during disable' );
  $run->soft_close;

  ok( -l $app1bin1,    'app1 bin1 file was not removed' );
  ok( -l $common_file, 'Common file was not removed' )
    or warn `ls -l "$common_file"`;

  @output = `$gpackage installed 2>&1`;
  is_deeply( [ sort @output ], ["app1\n"], 'app2 disabled' );

  #
  # Disable last package
  #
  $run = Test::Expect::Full->start( $gpackage, qw(disable app1) );
  $run->expect_like(
qr#.*Removing 3 elements.*${targetdir} was not deleted because it is not empty.*#s,
    'Target directory not removed during app1 disable'
  );
  $run->soft_close;

  ok( !-e File::Spec->catdir( $targetdir, 'bin' ),
      'bin directory was removed' );
  ok( !-e File::Spec->catdir( $targetdir, 'lib' ),
      'lib directory was removed' );

  my $output = `$gpackage installed 2>&1`;
  is( $output, '', 'No packages enabled' );
}

#
# Test suites
#

test_compile();
test_config();

# Clean up any test residues
tear_down();

test_installation();
test_enable_reenable();
test_enable_file_clash();
test_disable();

tear_down();

#done_testing();
