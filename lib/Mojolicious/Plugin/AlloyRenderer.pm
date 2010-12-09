
package Mojolicious::Plugin::AlloyRenderer;

use strict;
use warnings;

use base 'Mojolicious::Plugin';

use MojoX::Renderer::Alloy;

sub register {
    my ($self, $app, $args) = @_;
    $args ||= {};

    my $alloy = MojoX::Renderer::Alloy->build(%$args, app => $app);

    $app->renderer->add_handler(tt => $alloy);
}


1;

