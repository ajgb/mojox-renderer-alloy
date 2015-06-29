use strict;
use warnings;
package MojoX::Renderer::Alloy::Velocity;
#ABSTRACT: Template::Alloy's Velocity renderer

use base 'MojoX::Renderer::Alloy';

use Template::Alloy qw( Velocity );

__PACKAGE__->attr('alloy');

=head1 SYNOPSIS

Mojolicious

    $self->plugin( 'alloy_renderer',
        {
            syntax => 'Velocity',
        }
    );

Mojolicious::Lite

    plugin( 'alloy_renderer',
        {
            syntax => 'Velocity',
        }
    );

=head1 DESCRIPTION

    <a href="$h.url_for('about_us')">Hello!</a>

    #include('include.inc')

Use L<Template::Alloy::Velocity> for rendering.

Please see L<Mojolicious::Plugin::AlloyRenderer> for configuration options.

=cut

sub _render {
    my ($self, $r, $c, $output, $options) = @_;

    my $input = $self->_get_input( $r, $c, $options )
        || return;

    my $alloy = $self->alloy;

    # Template::Alloy won't handle undefined strings
    $$output = '' unless defined $$output;
    $alloy->merge( $input,
        $self->_template_vars( $c ),
        $output,
    ) || do {
        my $e = $alloy->error;
        chomp $e;
        $c->reply->exception( $e );

        return;
    };

    return 1;
}

1;
