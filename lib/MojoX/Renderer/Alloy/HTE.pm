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

    my $inc_path  = defined $app && $app->home->rel_dir('templates');

    my %config = (
        (
            $inc_path ?
            (
                path => [ $inc_path ]
            ) : ()
        ),
        ENCODING => 'UTF-8',
        %{ $args{template_options} || {} },
    );

    $self->_hte_config( \%config );
}

sub _render {
    my ($self, $r, $c, $output, $options) = @_;

    my $inline = $options->{inline};

    my $tname = $r->template_name($options);
    my $path = $r->template_path($options);

    return unless defined $inline || ( defined $path && defined $tname );


    my $alloy;
    # inline
    if ( defined $inline ) {
        $alloy = Template::Alloy->new(
            type => 'scalarref',
            source => \$inline,
            %{ $self->_hte_config },
        );
    }
    # regular file
    elsif ( -r $path ) {
        $alloy = Template::Alloy->new(
            type => 'filename',
            source => $path,
            %{ $self->_hte_config },
        );
    }
    else {
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

        return;
    };

    return 1;
}

1;