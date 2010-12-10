use strict;
use warnings;
package MojoX::Renderer::Alloy::Velocity;

use base 'MojoX::Renderer::Alloy';

use Template::Alloy qw( Velocity );

__PACKAGE__->attr('alloy');

sub _config {
    my ($self, %args) = @_;

    $self->alloy( Template::Alloy->new() );
}

sub _render {
    my ($self, $r, $c, $output, $options) = @_;

    my $input = $self->_get_input( $r, $c, $options )
        || return;

    my $alloy = $self->alloy;

    $$output = $alloy->merge( $input,
        {
            %{ $c->stash },
            c => $c,
        },
    ) || do {
        my $e = $alloy->error;
        chomp $e;
        $c->render_exception( $e );
    };
}

1;
