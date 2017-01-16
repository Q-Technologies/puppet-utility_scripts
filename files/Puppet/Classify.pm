package Puppet::Classify;

use JSON;
use LWP::UserAgent;
use HTTP::Request;
use 5.10.0;
use Moose;
use Moose::Exporter;

# We only need to activate storage when someone using us has already installed the module
# otherwise the following code can silently fail
eval {
    require MooseX::Storage;
    with Storage('format' => 'JSON', 'io' => 'File', traits => ['DisableCycleDetection']);
    1;
};

# Connect to the Puppet Classifier server on localhost by default - this can be overidden when consumed
has 'api_server' => (
    is => 'rw', 
    isa => 'Str',
    required => 1,
    default => 'localhost',
    predicate => 'has_api_server',
);
# Connect to the Puppet Classifier server on port 4433 by default - this can be overidden when consumed
has 'api_port' => (
    is => 'rw', 
    isa => 'Str',
    required => 1,
    default => '4433',
    predicate => 'has_api_port',
);
# Use a certificate by this name - localhost by default - this can be overidden when consumed
has 'cert_name' => (
    is => 'rw', 
    isa => 'Str',
    required => 1,
    default => 'localhost',
    predicate => 'has_cert_name',
);
# Set the path to the Puppet SSL certs - use the Puppet enterprise path by default
has 'puppet_ssl_path' => (
    is => 'rw', 
    isa => 'Str',
    required => 1,
    default => "/etc/puppetlabs/puppet/ssl",
    predicate => 'has_puppet_ssl_path',
);
# The connection timeout
has 'timeout' => (
    is => 'rw', 
    isa => 'Int',
    required => 1,
    default => 360,
    predicate => 'has_timeout',
);

around BUILDARGS => sub {
  my $orig  = shift;
  my $class = shift;

  if ( @_ == 1 && !ref $_[0] ) {
      return $class->$orig( api_server => $_[0] );
  }
  else {
      return $class->$orig(@_);
  }
};

sub get_group_rule {
    my $self = shift;
    my $name = shift;
    my $groups = $self->get_groups();
    for my $group ( @$groups ){
        return $group->{rule} if $group->{name} eq $name;
    }
}

sub get_group_id {
    my $self = shift;
    my $name = shift;
    my $groups = $self->get_groups();
    for my $group ( @$groups ){
        return $group->{id} if $group->{name} eq $name;
    }
}

sub get_groups_match {
    my $self = shift;
    my $match = shift;
    my @mgroups;
    my $groups = $self->get_groups();
    for my $group ( @$groups ){
        push @mgroups, $group if $group->{name} =~ /$match/i;
    }
    return \@mgroups;
}
sub get_groups {
    my $self = shift;
    my $groups = shift;
    return $self->get_data( "groups" );
}
sub get_child_groups {
    my $self = shift;
    my $gid = shift;
    return $self->get_data( "group-children/$gid" );
}
sub create_group {
    my $self = shift;
    my $group = shift;
    return $self->push_data( "groups", $group );
}
sub update_group_rule {
    my $self = shift;
    my $gid = shift;
    my $rule = shift;
    $self->push_data( "groups/$gid", { rule => $rule } );
}

sub update_classes {
    my $self = shift;
    $self->push_data( "update-classes" );
}

sub get_classes {
    my $self = shift;
    return $self->get_data( "environments/dev/classes" );
}

sub get_data {
    my $self = shift;
    my $action = shift;
    my $ua = LWP::UserAgent->new( timeout => $self->timeout, 
                                  ssl_opts => {
                                            verify_hostname => 1,
                                            SSL_cert_file => $self->puppet_ssl_path."/certs/".$self->cert_name.".pem",
                                            SSL_key_file => $self->puppet_ssl_path."/private_keys/".$self->cert_name.".pem",
                                            SSL_ca_file => $self->puppet_ssl_path."/certs/ca.pem"
                                         });
    my $query_uri = "https://".$self->api_server.":".$self->api_port."/classifier-api/v1/$action";
    #say $query_uri;
    my $response = $ua->get($query_uri);
    my $output;
    if ($response->is_success) {
        $output =  $response->decoded_content;
    } else {
        die $response->status_line."\n".$response->decoded_content;
    }

    my $data  = decode_json( $output );
    return $data;
}

sub push_data {
    my $self = shift;
    my $action = shift;
    my $data = shift;
    $data = encode_json( $data ) if ref $data;
    my $uri = "https://".$self->api_server.":".$self->api_port."/classifier-api/v1/$action";
    my $req = HTTP::Request->new( 'POST', $uri );
    $req->header( 'Content-Type' => 'application/json' );
    $req->content( $data );
    my $ua = LWP::UserAgent->new( timeout => $self->timeout, 
                                  ssl_opts => {
                                            verify_hostname => 1,
                                            SSL_cert_file => $self->puppet_ssl_path."/certs/".$self->cert_name.".pem",
                                            SSL_key_file => $self->puppet_ssl_path."/private_keys/".$self->cert_name.".pem",
                                            SSL_ca_file => $self->puppet_ssl_path."/certs/ca.pem"
                                         });
    my $response = $ua->request( $req ); 
    my $output;
    if ($response->is_redirect( 303 ) or $response->is_success( 201 )) {
        $output =  $response->decoded_content;
    } else {
        die $response->status_line ."\n".$response->decoded_content;
    }
}

sub delete_group {
    my $self = shift;
    my $id = shift;
    my $ua = LWP::UserAgent->new( timeout => $self->timeout, 
                                  ssl_opts => {
                                            verify_hostname => 1,
                                            SSL_cert_file => $self->puppet_ssl_path."/certs/".$self->cert_name.".pem",
                                            SSL_key_file => $self->puppet_ssl_path."/private_keys/".$self->cert_name.".pem",
                                            SSL_ca_file => $self->puppet_ssl_path."/certs/ca.pem"
                                         });
    my $response = $ua->delete("https://".$self->api_server.":".$self->api_port."/classifier-api/v1/groups/$id");
    die $response->status_line."\n".$response->decoded_content if not $response->is_success( 204 );
}

1;
