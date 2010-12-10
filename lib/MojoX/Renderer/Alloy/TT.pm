use strict;
use warnings;
package MojoX::Renderer::Alloy::TT;

use base 'MojoX::Renderer::Alloy';

use Template::Alloy qw( TT );
use File::Spec ();

__PACKAGE__->attr('alloy');

sub _init {
    my ($self, %args) = @_;

    my $app = delete $args{app} || delete $args{mojo};

    my $compile_dir = defined $app && $app->home->rel_dir('tmp/ctpl');
    my $inc_path  = defined $app && $app->home->rel_dir('templates');

    my %config = (
        (
            $inc_path ?
            (
                INCLUDE_PATH => $inc_path
            ) : ()
        ),
        COMPILE_EXT => '.ttc',
        COMPILE_DIR => ( $compile_dir || File::Spec->tmpdir ),
        UNICODE     => 1,
        ENCODING    => 'utf-8',
        CACHE_SIZE  => 128,
        RELATIVE    => 1,
        ABSOLUTE    => 1,
        %{ $args{template_options} || {} },
    );

    $self->alloy( Template::Alloy->new(%config) );
}

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
