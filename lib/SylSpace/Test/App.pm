package SylSpace::Test::App;

use Mojo::Base 'Test2::MojoX';
use Mojo::File qw(curfile);
use Test2::API qw(context);

# we provide a new constructor which finds the app
sub new_app {
  my ($self) = @_;
  my $t = $self->new(
    curfile->dirname->dirname->dirname->sibling('SylSpace'),
    { site_name => 'lvh.me' });
  $t->ua->max_redirects(5);

  return $t
}

# a testing function to hit the server on a particular subdomain
sub get_on_domain_ok {
  my ($t, $domain, $path, @query) = @_;
  my $ctx = context;

  my $url = $t->ua->server->url->clone->to_abs
    ->path($path);

  $url->host('lvh.me');
  $url->host("$domain.lvh.me") if $domain;
  $url->query(@query) if @query;
  $t->get_ok($url);

  $ctx->release;
  return $t
}

sub post_on_domain_ok {
  my ($t, $domain, $path, @args) = @_;
  my $ctx = context;
  my $url = $t->ua->server->url->clone->to_abs
    ->path($path);
  $url->host('lvh.me');
  $url->host("$domain.lvh.me") if $domain;

  $t->post_ok($url, @args);

  $ctx->release;
  return $t
}


9004
