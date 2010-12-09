use strict;
use warnings;
package MojoX::Renderer::Alloy;

use warnings;
use strict;

use base 'Mojo::Base';

use Template::Alloy qw( TT );
use File::Spec ();
use Mojo::Util 'md5_sum';

__PACKAGE__->attr('alloy');

sub build {
    my $self = shift->SUPER::new(@_);

    $self->_init(@_);

    return sub { $self->_render(@_) };
};

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

    my $inline = $options->{inline};

    my $tname = $r->template_name($options);
    my $path = $r->template_path($options);

    $path = \$inline if defined $inline;

    return unless defined $path && defined $tname;

    my $input = ref $path ? $path # inline
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
