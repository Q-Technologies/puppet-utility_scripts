package String::ShortHostname;

use Moose;
use Moose::Exporter;

Moose::Exporter->setup_import_methods(
      as_is     => [ 'short_hostname' ],
  );

has 'hostname' => (
    is => 'rw', 
    isa => 'Str',
    required => 1,
    default => '',
    predicate => 'has_hostname',
);

around BUILDARGS => sub {
  my $orig  = shift;
  my $class = shift;

  if ( @_ == 1 && !ref $_[0] ) {
      return $class->$orig( hostname => $_[0] );
  }
  else {
      return $class->$orig(@_);
  }
};

around 'hostname' => sub {
    my $orig = shift;
    my $self = shift;

    return $self->$orig() unless @_;

    return $self->$orig( short_hostname( shift ) );
};

sub short_hostname {
    my $hostname = shift;
    my @bits;
    @bits = split /\./, $hostname if $hostname;
    my $alpha_found;
    for( @bits ){
        $alpha_found = 1 if /\D/;
    }
    if( $alpha_found ){
        return $bits[0];
    } else {
        return $hostname; # probably an IP Address
    }
}


1;
