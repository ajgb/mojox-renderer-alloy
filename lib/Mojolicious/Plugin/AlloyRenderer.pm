
package Mojolicious::Plugin::AlloyRenderer;
#ABSTRACT: Template::Alloy renderer plugin

use strict;
use warnings;

use base 'Mojolicious::Plugin';

use Mojo::Loader qw/load_class/;

=head1 SYNOPSIS

Mojolicious

    $self->plugin( 'alloy_renderer' );

    $self->plugin( 'alloy_renderer',
        {
            syntax => 'TT',
            template_options => {
                TRIM => 1,
                PRE_CHOMP => 1,
                POST_CHOMP => 1,
            }
        }
    );

Mojolicious::Lite

    plugin( 'alloy_renderer' );

    plugin( 'alloy_renderer',
        {
            syntax => 'TT',
            template_options => {
                TRIM => 1,
                PRE_CHOMP => 1,
                POST_CHOMP => 1,
            }
        }
    );

=head1 DESCRIPTION

L<Mojolicious::Plugin::AlloyRenderer> is a loader for
L<MojoX::Renderer::Alloy>.

=cut

=method register

    $plugin->register( %config );

Registers this plugin within Mojolicious application.

Following options are supported:

=over

=item syntax

Default syntax is C<TT>.

    $plugin->register(
        syntax => 'TT',
    );

Possible scalar values are:

    # syntax    # default extension (handler)   # syntax
    TT          tt                              Template::Alloy::TT
    Velocity    vtl                             Template::Alloy::Velocity
    Tmpl        tmpl                            Template::Alloy::Tmpl
    HTE         hte                             Template::Alloy::HTE

You may also choose your own templates extensions (handler):

    $plugin->register(
        syntax => { 'TT' => 'tt3' },
    );

or enable multiple templating engines at once:

    # with default extensions
    $plugin->register(
        syntax => [qw( TT Tmpl )],
    );
    # or all
    $plugin->register(
        syntax => ':all',
    );

    # with custom extensions
    $plugin->register(
        syntax => {
            'TT' => 'tt3',
            'HTE' => 'ht',
        },
    );

Chosen syntax will be set as default handler by calling
L<Mojolicious::Renderer/"default_handler">.

Please note that if you pass multiple options the last one will be set as
default (random in case of hashref).

=item template_options

    $plugin->register(
        template_options => {
            INCLUDE_PATH => $app->home->rel_dir('templates'),
            COMPILE_EXT => '.ct',
            COMPILE_DIR => ( $app->home->rel_dir('tmp/ctpl') || File::Spec->tmpdir ),
            UNICODE     => 1,
            ENCODING    => 'utf-8',
            CACHE_SIZE  => 128,
            RELATIVE    => 1,
            ABSOLUTE    => 1,
        }
    );

Configuration options as described in L<Template::Alloy/"CONFIGURATION">.

Above are the default options for all engines.

=back

=cut

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
                    for sort keys %syn2ext;
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

    for my $syn ( @setup ) {
        my ($module, $extension) = @$syn;
        my $class = "MojoX::Renderer::Alloy::$module";

        load_class( $class );

        my $alloy = $class->build(%$args, app => $app);

        $app->renderer->add_handler($extension => $alloy);
        $app->renderer->default_handler($extension);
    }
}


1;

