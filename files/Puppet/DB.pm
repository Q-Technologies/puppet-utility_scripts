package Puppet::DB;

use LWP::UserAgent;
use HTTP::Request;
use JSON;
use Time::Local;
use Moose;
use Moose::Exporter;
use String::ShortHostname;

# We only need to activate storage when someone using us has already installed the module
# otherwise the following code can silently fail
eval {
    require MooseX::Storage;
    with Storage('format' => 'JSON', 'io' => 'File', traits => ['DisableCycleDetection']);
    1;
};

# Connect to the Puppet DB server on localhost by default - this can be overidden when consumed
has 'server_name' => (
    is => 'rw', 
    isa => 'Str',
    required => 1,
    default => 'localhost',
    predicate => 'has_server_name',
);
# Connect to the Puppet DB server on port 8080 by default - this can be overidden when consumed
has 'server_port' => (
    is => 'rw', 
    isa => 'Int',
    required => 1,
    default => 8080,
    predicate => 'has_server_port',
);
# property to store facts
has 'facts' => (
    is => 'rw', 
    isa => 'ArrayRef',
    default => sub { [] },
    predicate => 'has_facts',
);

# property to store more generic results
has 'results' => (
    is => 'rw', 
    isa => 'ArrayRef',
    default => sub { [] },
    predicate => 'has_results',
);

around BUILDARGS => sub {
  my $orig  = shift;
  my $class = shift;

  if ( @_ == 1 && !ref $_[0] ) {
      return $class->$orig( server_name => $_[0] );
  }
  else {
      return $class->$orig(@_);
  }
};

sub parse_puppetdb_time {
    my $in_time = shift;
    my $time;
    # 2016-02-08T02:21:04.417Z
    if( $in_time =~ /(\d\d\d\d)-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d\.*\d*)Z/ ){
        my( $year, $mon, $mday, $hour, $min, $sec ) = ( $1, $2, $3, $4, $5, $6 );
        my $time = timegm( $sec, $min, $hour, $mday, $mon-1, $year );
    } else {
        $time = 0;
    }
}

sub refresh_facts {
    my $self = shift;
    my $query = shift;
    $query = {} if ! $query;
    refresh( $self, 'facts', $query );
    $self->facts( $self->results );

}


sub refresh {
    my $self = shift;
    my $api_server = $self->server_name;
    my $api_port = $self->server_port;
    my $action = shift;
    my $data = encode_json( shift );
    my $uri = "http://$api_server:$api_port/pdb/query/v4/$action";
    my $req = HTTP::Request->new( 'POST', $uri );
    $req->header( 'Content-Type' => 'application/json' );
    $req->content( $data );
    my $ua = LWP::UserAgent->new();
    my $response = $ua->request( $req ); 
    my $output;
    if ($response->is_success) {
        $output =  $response->decoded_content;
    } else {
        die $response->status_line;
    }
    $data  = decode_json( $output );
    $self->results( $data );
}

sub allfacts_by_certname {
    my $self = shift;
    my $facts = $self->facts;
    my $data = {};
    for my $fact_element ( @$facts ){
        $data->{$fact_element->{certname}}{$fact_element->{name}} = $fact_element->{value};
    }
    return $data;
}

sub allfacts_by_hostname {
    my $self = shift;
    my $facts = $self->facts;
    my $data = {};
    for my $fact_element ( @$facts ){
        $data->{short_hostname($fact_element->{certname})}{$fact_element->{name}} = $fact_element->{value};
    }
    return $data;
}

sub get_fact {
    return get_fact_by_certname( shift, shift, shift );
}

sub get_fact_by_certname {
    my $self = shift;
    my $facts = $self->facts;
    my $fact = shift;
    my $certname = shift;
    for my $fact_element ( @$facts ){
        if( $fact eq $fact_element->{name} and $certname eq $fact_element->{certname} ){
            return $fact_element->{value};
        }
    }
}

sub get_fact_by_short_hostname {
    my $self = shift;
    my $facts = $self->facts;
    my $fact = shift;
    my $shortname = shift;
    for my $fact_element ( @$facts ){
        if( $fact eq $fact_element->{name} and $fact_element->{certname} =~ /$shortname(\..+)*/ ){
            return $fact_element->{value};
        }
    }
}


1;
