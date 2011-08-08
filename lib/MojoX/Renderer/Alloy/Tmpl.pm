use strict;
use warnings;
package MojoX::Renderer::Alloy::Tmpl;
#ABSTRACT: Template::Alloy's Text::Tmpl renderer

use base 'MojoX::Renderer::Alloy';

use Template::Alloy qw( Tmpl );

__PACKAGE__->attr('alloy');

=head1 SYNOPSIS

Mojolicious

    $self->plugin( 'alloy_renderer',
        {
            syntax => 'Tmpl',
        }
    );

Mojolicious::Lite

    plugin( 'alloy_renderer',
        {
            syntax => 'Tmpl',
        }
    );

=head1 DESCRIPTION

    <a href="#[ echo h.url_for('about_us') ]#">Hello!</a>

    #[include "include.inc"]#

Use L<Template::Alloy::Tmpl> for rendering.

Please see L<Mojolicious::Plugin::AlloyRenderer> for configuration options.

Note: default delimiters (I<START_TAG> and I<END_TAG>) are C<#[> and C<]#>.

=cut

sub _init {
    my $self = shift;

    my %config = (
        START_TAG   => '#[',
        END_TAG   => ']#',
        $self->_default_config(@_),
    );

    my $alloy = Template::Alloy->new(
        %config,
    );

    $alloy->set_dir( $config{INCLUDE_PATH} )
        if exists $config{INCLUDE_PATH};

    $alloy->set_delimiters(@config{qw(START_TAG END_TAG)});

    $self->alloy( $alloy );
}

sub _render {
    my ($self, $r, $c, $output, $options) = @_;

    my $inline = $options->{inline};

    my $tname = $r->template_name($options);
    my $path = $r->template_path($options);

    return unless defined $inline || ( defined $path && defined $tname );

    my $method;
    # inline
    if ( defined $inline ) {
        $method = 'parse_string';
        $path = $inline;
    }
    # regular file
    elsif ( -r $path ) {
        $method = 'parse_file';
    } else {
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

    my $alloy = $self->alloy;
    $alloy->set_values(
        $self->_template_vars( $c )
    );

    eval {
        $$output = $alloy->$method( $path );
    };
    if ( my $e = $alloy->error || $@ ) {
        chomp $e;
        $c->render_exception( $e );

        return;
    };

    return 1;
}

1;
