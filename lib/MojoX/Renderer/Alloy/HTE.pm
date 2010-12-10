use strict;
use warnings;
package MojoX::Renderer::Alloy::HTE;

use base 'MojoX::Renderer::Alloy';

use Template::Alloy qw( HTE );
use File::Spec ();

__PACKAGE__->attr('_hte_config');

sub _init {
    my ($self, %args) = @_;

    my $app = delete $args{app} || delete $args{mojo};

    my $compile_dir = defined $app && $app->home->rel_dir('tmp/ctpl');
    my $inc_path  = defined $app && $app->home->rel_dir('templates');

    my %config = (
        (
            $inc_path ?
            (
                path => [ $inc_path ]
            ) : ()
        ),
        file_cache => 1,
        file_cache_dir => ( $compile_dir || File::Spec->tmpdir ),
        %{ $args{template_options} || {} },
    );

    $self->_hte_config( \%config );
}

sub _render {
    my ($self, $r, $c, $output, $options) = @_;

    my $inline = $options->{inline};

    my $tname = $r->template_name($options);
    my $path = $r->template_path($options);

    $path = \$inline if defined $inline;

    return unless defined $path && defined $tname;

    my $alloy;

    # inline
    if ( ref $path ) {
        $alloy = Template::Alloy->new_scalar_ref( $path,
            %{ $self->_hte_config }
        );
    }
    # regular file
    elsif ( -r $path ) {
        $alloy = Template::Alloy->new_file( $path,
            %{ $self->_hte_config }
        );
    } else {
        # inlined templates are not supported
        if ( $r->get_inline_template($options, $tname) ) {
            $c->render_exception(
                "Inlined templates are not supported"
            );
        } else {
            $c->render_not_found( $tname );
        };
        return;
    }

    $alloy->param( 
        {
            %{ $c->stash },
            c => $c,
        },
    );

    eval {
        $$output = $alloy->output();
    };
    if ( my $e = $alloy->error || $@ ) {
        chomp $e;
        $c->render_exception( $e );
    };
}

1;
