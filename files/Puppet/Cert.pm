package Puppet::Cert;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(parse_csr);

# Do some crude parsing of the CSR.  This has only been tested on the
# Puppet CSRs but presumably it would be generic.  Basically, we look
# for the embedded extensions and put them into a hash array using 
# their OID numbers as the keys.
sub parse_csr {
    my $csr = shift;
    my @cert = `echo "$csr" | openssl req -text -noout` or die $!;
    my $key;
    my %extensions;
    my $interesting_bit = 0;
    for( @cert ){
        $interesting_bit = 1 if( /Requested Extensions:/ );
        $interesting_bit = 0 if( /Signature Algorithm:/ );
        if( $interesting_bit ){
            if( /(\d+\.\d+\.\d+\.\d+\.\d+\.\d+\.\d+\.\d+\.\d+\.\d+):/ ){
                $key = $1;
            } elsif ( $key ) {
                $extensions{$key} .= $_;
            }
        }
    }
    for my $key ( keys %extensions ) {
        for( $extensions{$key} ){
            s/\./ /g;
            s/^\s+|\s+$//g;
        }
    }
    return \%extensions;
}

1;
