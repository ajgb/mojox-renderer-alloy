use strict;
use warnings;
package MojoX::Renderer::Alloy::Velocity;

use base 'MojoX::Renderer::Alloy';

use Template::Alloy qw( Velocity );

__PACKAGE__->attr('alloy');

sub _init {
    my ($self, %args) = @_;

    my $app = delete $args{app} || delete $args{mojo};

    my $inc_path  = defined $app && $app->home->rel_dir('templates');

    my %config = (
        (
            $inc_path ?
            (
                INCLUDE_PATH => $inc_path
            ) : ()
        ),
        UNICODE     => 1,
        ENCODING    => 'utf-8',
        RELATIVE    => 1,
        ABSOLUTE    => 1,
        %{ $args{template_options} || {} },
    );

    my $alloy = Template::Alloy->new(
        %config,
    );

    $self->alloy( $alloy );
}

sub _render {
    my ($self, $r, $c, $output, $options) = @_;

    my $input = $self->_get_input( $r, $c, $options )
        || return;

    my $alloy = $self->alloy;

    # Template::Alloy won't handle undefined strings
    $$output = '' unless defined $$output;
    $alloy->merge( $input,
        {
            %{ $c->stash },
            c => $c,
        },
        $output,
    ) || do {
        my $e = $alloy->error;
        chomp $e;
        $c->render_exception( $e );

        return;
    };

    return 1;
}

1;
