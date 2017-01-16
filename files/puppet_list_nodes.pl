#!/usr/bin/perl

# This script is for list nodes in Puppet groups that control
# 
# It makes the following assumptions:
#   * The parent group is 'All Nodes' - do not change this group!
#
# Author: Matthew Mallard
# Website: www.q-technologies.com.au
# Date: 16th January 2017

use strict;
use 5.10.0;
use JSON;
use vars qw/$puppet_config/;
BEGIN { 
  local $/;
  open( my $fh, '<', "/usr/local/etc/puppet_perl_config.json" );
  my $json_text   = <$fh>;
  $puppet_config = decode_json( $json_text )or die $!;    
}
use lib @{$puppet_config->{locallibs}};
use Data::Dumper;
use String::CamelCase qw( camelize );
use Puppet::Classify;
use Puppet::DB;
use Getopt::Std;
use Log::MixedColor;

# Command line argument processing
our( $opt_a, $opt_m, $opt_h, $opt_v, $opt_d, $opt_f );
getopts('a:m:hvdf');
$Getopt::Std::STANDARD_HELP_VERSION = 1;

# Set up logging
my $log = Log::MixedColor->new( verbose => $opt_v, debug => $opt_d );

# Globals
my $nodes;
my $parent_id;
my $parent = "All Nodes";
my @actions = qw(all in_group match_fact match_name );

my $classify = Puppet::Classify->new( 
                                      cert_name   => $puppet_config->{puppet_classify_cert},
                                      api_server  => $puppet_config->{puppet_classify_host},
                                      api_port    => $puppet_config->{puppet_classify_port},
                                    );

my $puppetdb = Puppet::DB->new(       
                                      server_name => $puppet_config->{puppetdb_host},
                                      server_port => $puppet_config->{puppetdb_port},
                                    );
$puppetdb->refresh("nodes", {});
my $puppetdb_nodes = $puppetdb->results;

# Preliminary input checks
if( $opt_h ){
    say "\n$0 -a action [-m group|fact|node] [-f] [-v] [-d]";
    say "\nThe following actions are supported:";
    for( @actions ){
        say "\t".$_;
    }
    say;
    say "-m is string to match. Specify as a Perl regular expression without the /'s";
    say "\t'group' is a Puppet Enterprise Console group";
    say "\t'fact' is a PuppetDB fact";
    say "\t'node' is a Puppet node - i.e. clientcert";
    say;
    say "-f is force. Sometimes required as a layer of safety";
    say "-v is to show verbose messages";
    say "-d is to show debug messages";
    say;
    exit;
}
my $action_re = join("|", @actions);
$action_re = qr/$action_re/;
$log->fatal_err( "You need to specify the script action: -a ".join(" | ", @actions ) ) if not $opt_a =~ $action_re;
$log->fatal_err( "You need to specify the string to use as the regular expression (-m)" ) if not $opt_m and $opt_a !~ /all/;

# Mainline
my $groups = $classify->get_groups();
#say Dumper( $groups );

if( $opt_a eq "all" ){
    list_all_nodes();
} elsif( $opt_a eq "in_group" ){
    say "Not implemented yet!";
} elsif( $opt_a eq "match_fact" ){
    say "Not implemented yet!";
} elsif( $opt_a eq "match_name" ){
    say "Not implemented yet!";
} else {
    $log->fatal_err( "The action: '$opt_a' is not known to the script" );
    exit 1;
}

sub list_all_nodes {
    for my $node ( @$puppetdb_nodes ){
        say $node->{certname};
    }
}
