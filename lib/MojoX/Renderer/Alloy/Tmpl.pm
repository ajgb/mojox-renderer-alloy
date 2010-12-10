use strict;
use warnings;
package MojoX::Renderer::Alloy::Tmpl;

use base 'MojoX::Renderer::Alloy';

use Template::Alloy qw( Tmpl );

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
        START_TAG   => '#[',
        END_TAG   => ']#',
        %{ $args{template_options} || {} },
    );

    my $alloy = Template::Alloy->new(
        %config,
    );

    $alloy->set_dir( $inc_path )
        if $inc_path;
    $alloy->set_delimiters(@config{qw(START_TAG END_TAG)});

    while ( my ($option, $value) = each %{ $args{template_options} || {} } ) {
        if ( my $m = $alloy->can($option) ) {
            $m->($alloy, $value);
        }
    }

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
        if ( $r->get_inline_template($options, $tname) ) {
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
        {
            %{ $c->stash },
            c => $c,
        },
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
