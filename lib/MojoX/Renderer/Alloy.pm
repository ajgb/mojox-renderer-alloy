use strict;
use warnings;
package MojoX::Renderer::Alloy;

use base 'Mojo::Base';

sub build {
    my $self = shift->SUPER::new(@_);

    $self->_init(@_);

    return sub { $self->_render(@_) };
};

sub _get_input {
    my ( $self, $r, $c, $options ) = @_;

    my $inline = $options->{inline};

    my $tname = $r->template_name($options);
    my $path = $r->template_path($options);

    $path = \$inline if defined $inline;

    return unless defined $path && defined $tname;

    return ref $path ? $path # inline
        : -r $path ?
            $path # regular file
            :
            do { # inlined templates are not supported
                if ( $r->get_inline_template($options, $tname) ) {
                    $c->render_exception(
                        "Inlined templates are not supported"
                    );
                } else {
                    $c->render_not_found( $tname );
                }
                return;
            };
};

1;
