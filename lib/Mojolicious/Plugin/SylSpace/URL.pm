package Mojolicious::Plugin::SylSpace::URL;
use Mojo::Base 'Mojolicious::Plugin';

sub register {
  my ($self, $app, $conf) = @_;

  #TODO- NOENV - maybe just never use this, and use a helper like
  #auth_path
  $app->helper(domainport => sub {
    my $c = shift;
    my $port = $c->req->url->to_abs->port;
    my $site = $c->sitename;
    (defined($port)) or return $site;
    return "$site:$port";
  });

  $app->helper(auth_path => sub {
    my ($c, $path) = @_;
    $c->req->url->to_abs->clone
      ->path($path)
      ->host(join '.', 'auth', $c->sitename)
      ->query(undef);
  });
    

  $app->helper(subdomain => sub {
    my $domain = shift->req->url->to_abs->host;
    return '' if $domain eq '127.0.0.1';
    ($domain =~ m/(.*)\.localhost$/) and return $1;
    my @f = split(/\./, $domain);
    return '' unless @f;  ## never
    splice @f, -2; #pop off tld and main site name
    return join '.', @f;
  });

  $app->helper(sitename => sub {
    $app->config->{site_name} || 'lvh.me'
  });

}


9043
