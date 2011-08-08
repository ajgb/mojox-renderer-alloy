use strict;
use warnings;
package MojoX::Renderer::Alloy::HTE;
#ABSTRACT: Template::Alloy's HTML::Template::Expr renderer

use base 'MojoX::Renderer::Alloy';

use Template::Alloy qw( HTE );
use File::Spec ();

__PACKAGE__->attr('_hte_config');

=head1 SYNOPSIS

Mojolicious

    $self->plugin( 'alloy_renderer',
        {
            syntax => 'HTE',
        }
    );

Mojolicious::Lite

    plugin( 'alloy_renderer',
        {
            syntax => 'HTE',
        }
    );

=head1 DESCRIPTION

    <a href="<TMPL_VAR EXPR="h.url_for('about_us')">"Hello!</a>

    <TMPL_INCLUDE NAME="include.inc">

Use L<Template::Alloy::HTE> for rendering.

Please see L<Mojolicious::Plugin::AlloyRenderer> for configuration options.

=cut

sub _init {
    my $self = shift;

    my %config = $self->_default_config(@_);

    $config{path} = $config{INCLUDE_PATH}
        unless exists $config{path};

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
        if ( $r->get_data_template($options, $tname) ) {
            $c->render_exception(
                "Inlined templates are not supported"
            );
        } else {
            $c->render_not_found( $tname );
        };
        return;
    }

    $alloy->param(
        $self->_template_vars( $c )
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
