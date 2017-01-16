# Author: Matthew Mallard
# Website: www.q-technologies.com.au
# Date: 6th October 2016
# 
package Log::MixedColor;
use Moose;
use Moose::Exporter;
use 5.10.0;
use Term::ANSIColor;

use constant DEBUG_MSG => "debug";
use constant ERROR_MSG => "error";

# We only need to activate storage when someone using us has already installed the module
# otherwise the following code can silently fail
eval {
    require MooseX::Storage;
    with Storage('format' => 'JSON', 'io' => 'File', traits => ['DisableCycleDetection']);
    1;
};


has 'verbose' => (
    is => 'rw', 
    isa => 'Bool',
    default => 0,
    predicate => 'is_verbose',
);

has 'debug' => (
    is => 'rw', 
    isa => 'Bool',
    default => 0,
    predicate => 'is_debug',
);




sub info_msg {
    my $self = shift;
    chomp( my $msg = shift );
    my $level = shift;
    $level = "" if ! $level;
    my $color = "green";
    my $var_col = "black on_white";
    my $prefix = "Info";
    my $say = ($self->verbose or $self->debug);
    my $extra_nl = "";
    my $excl = "";
    my $fh = *STDOUT;
    if( $level eq DEBUG_MSG ){
        $color = "magenta";
        $var_col = "blue";
        $prefix = "Debug";
        $say = $self->debug;
    } elsif( $level eq ERROR_MSG ){
        $color = "red";
        $var_col = "yellow";
        $prefix = "Error";
        $say = 1;
        $extra_nl = "\n";
        $excl = "!";
        $fh = *STDERR;
    }
    for( $msg ){
        my $code1 = color("reset").color( $var_col );
        my $code2 = color("reset").color( $color );
        s/%%/$code1/g;
        s/##/$code2/g;
    }
    say $fh color($color).$extra_nl.$prefix.": ".$msg.$excl.$extra_nl.color("reset") if $say;
}

sub quote {
    my $self = shift;
    return '%%'.shift().'##';
}

sub debug_msg {
    my $self = shift;
    my $msg = shift;
    info_msg( $msg, DEBUG_MSG );
}

sub fatal_err {
    my $self = shift;
    my $msg = shift;
    my $val = shift;
    $val = 1 if ! defined( $val );
    info_msg( $self, $msg, ERROR_MSG );
    exit $val;
}

sub err_msg {
    my $self = shift;
    my $msg = shift;
    info_msg( $self, $msg, ERROR_MSG );
}


1;
