
package Mojolicious::Plugin::AlloyRenderer;

use strict;
use warnings;

use base 'Mojolicious::Plugin';

use Mojo::Loader;

my %syn2ext = (
    'TT' => 'tt',
    'Velocity' => 'vtl',
    'Tmpl' => 'tmpl',
    'HTE' => 'hte',
);

sub register {
    my ($self, $app, $args) = @_;
    $args ||= {};

    my @setup;
    if ( my $s = delete $args->{syntax} ) {
        # default extensions
        # syntax => [qw( TT HTE )]
        if ( ref $s eq 'ARRAY' ) {
            push @setup, [ $_ => $syn2ext{$_} ]
                for @$s;
        }
        # custom extensions
        # syntax => {(TT => 'tt3', HTE => 'ht' )}
        elsif ( ref $s eq 'HASH' ) {
            while (my($k,$v) = each %$s) {
                push @setup, [ $k => $v ];
            }
        }
        # single syntax with default extension
        # syntax => 'HTE'
        elsif ( ! ref $s ) {
            if ( $s eq ':all' ) {
                push @setup, [ $_ => $syn2ext{$_} ]
                    for keys %syn2ext;
            } else {
                push @setup, [ $s => $syn2ext{$s} ];
            }
        }
        else {
            die "Unrecognised configuration for 'alloy_renderer' plugin: $s\n";
        }
    # defaults to TT
    } else {
        push @setup, [ TT => $syn2ext{TT} ];
    }

    my $loader = Mojo::Loader->new;

    for my $syn ( @setup ) {
        my ($module, $extension) = @$syn;
        my $class = "MojoX::Renderer::Alloy::$module";

        $loader->load( $class );

        my $alloy = $class->build(%$args, app => $app);

        $app->renderer->add_handler($extension => $alloy);

    }
}


1;

