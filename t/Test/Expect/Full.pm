package Test::Expect::Full;

use base qw'Expect Test::Builder::Module';

=head1 NAME

Test::Expect::Full - simplify testing with expect

=head1 SYNOPSIS

  use Test::Expect::Full plan => 1;
  my $run = Test::Expect::Full->start( "pingpong" );
  $run->expect_like(qr/Pingpong started.*Awaiting ping/");
  $run->send( "ping\n" );
  $run->expect_is( "pong\n", 'pong received' );
  $run->send( "bye\n" );
  $run->soft_close;

=head1 DESCRIPTION

This class simplifies testing external commands using L<Expect> and
L<Test::Builder>. Its existence was motivated because L<Test::Expect> is based
on L<Expect::Simple> and cannot be used with commands which lack disconnect
command and prompt.

The class inherits from both L<Expect> and L<Test::Builder::Module>, so it has
all the power of both super classes, which really are super classes.

=head1 CLASS VARIABLES

=head2 $multiline_matching

Define how to handle multi-line matching. If it is "undef", then regexes will
be sent to L<Expect::expect> as-is. If it is defined, then
L<Expect::Multiline_Matching> is set to the value of
C<$Test::Expect::Full::multiline_matching> during the C<expect> call, and
restored afterwards. Default is to not use multiline matching (false). Example:

  $Test::Expect::Full::multiline_matching = undef; # Use Expect's setting

See L<Expect>. This setting can always be overridden by the user with regex
modifiers.

=cut

#our $multiline_matching = 0;

=head1 METHODS

=head2 start

This methods spawns an external process and returns a new L<Test::Expect::Full>
object.  I takes the same arguments as L<Expect::spawn>, but sets the pty to
"raw", and stops logging to stdout, to avoid unwanted output. C<undef> is
returned if the process could not be spawed.

=cut

sub start {
  my $class = shift @_;
  my $self  = $class->SUPER::new;
  $self or return $self;
  $self->raw_pty(1);
  $self->log_stdout(0);
  $self->spawn(@_) or return undef;
  return $self;
}

=head2 expect_is

Appects a string, a test name, and an optional timeout. The string is matched
with the spawned process' output using to L<Expect::expect>. The timeout
defaults to 2 seconds if not specified.

=cut

sub expect_is {
  my ( $self, $string, $name, $timeout ) = @_;
  $timeout = 2 unless defined $timeout;

  $self->expect( 2, $string );

  my $tb = __PACKAGE__->builder;

  return $tb->is_eq( $self->before . $self->match . $self->after, $string,
                     $name );
}

=head2 expect_like

Appects a regular expression, a test name and an optional timeout. The regular
expression is matched with the spawned process' output using L<Expect::expect>.
The timeout defaults to 2 seconds if not specified.

=cut

sub expect_like {
  my ( $self, $regexp, $name, $timeout ) = @_;
  $timeout = 2 unless defined $timeout;

  $self->expect( 2, '-re', $regexp );

  my $tb = __PACKAGE__->builder;

  return $tb->like( $self->before . $self->match . $self->after, $regexp,
                    $name );
}

1;

=head1 SEE ALSO

L<Expect>, L<Test::Builder>, L<Test::Expect>

