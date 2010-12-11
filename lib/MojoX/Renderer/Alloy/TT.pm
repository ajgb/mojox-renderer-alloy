use strict;
use warnings;
package MojoX::Renderer::Alloy::TT;
#ABSTRACT: Template::Alloy's Template-Toolkit renderer

use base 'MojoX::Renderer::Alloy';

use Template::Alloy qw( TT );
use File::Spec ();

__PACKAGE__->attr('alloy');

=head1 SYNOPSIS

Mojolicious

    $self->plugin( 'alloy_renderer' );

Mojolicious::Lite

    plugin( 'alloy_renderer' );

=head1 DESCRIPTION

    <a href="[% c.url_for('about_us') %]">Hello!</a>

    [% INCLUDE "include.inc" %]

Use L<Template::Alloy::TT> for rendering.

Please see L<Mojolicious::Plugin::AlloyRenderer> for configuration options.

=cut


sub _render {
    my ($self, $r, $c, $output, $options) = @_;

    my $input = $self->_get_input( $r, $c, $options )
        || return;

    my $alloy = $self->alloy;

    $alloy->process( $input,
        {
            %{ $c->stash },
            c => $c,
        },
        $output,
        { binmode => ':utf8' },
    ) || do {
        my $e = $alloy->error;
        chomp $e;
        $c->render_exception( $e );
    };
}

1;
