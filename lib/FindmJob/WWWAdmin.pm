package FindmJob::WWWAdmin;

use Mojo::Base 'Mojolicious';
use FindmJob::Basic;
use File::Spec::Functions 'catdir';

sub startup {
    my $self = shift;

    my $config = FindmJob::Basic->config;
    $config->{hypnotoad} = {
        listen => ['http://*:8081'],
        workers => 2,
    };
    $self->secret($config->{secret_hash});
    $self->helper(sconfig => sub { return $config });
    $self->helper(schema => sub { FindmJob::Basic->schema });
    unshift @{$self->static->paths}, catdir( FindmJob::Basic->root, 'static' );

    $self->plugin('charset' => {charset => 'UTF-8'});
    $self->plugin('tt_renderer' => {
        template_options => {
            WRAPPER => 'wrapper.tt2',
            FILTERS => {
                seo_title => \&seo_title,
            }
        }
    });
    $self->renderer->default_handler( 'tt' );

    my $r = $self->routes;
    $r->namespaces(['FindmJob::WWWAdmin']);

    $self->plugin('basic_auth');
    $r = $r->under(sub {
        my $self = shift;
        return $self->render(text => 'Permission Denied.')
          unless $self->basic_auth(
                  realm => sub { return 1 if "@_" eq $config->{admin}->{auth} }
          );
    });

    $r->any('/')->to(controller => 'Root', action => 'index');

}

1;