use SylSpace::Test
  make_test_site => 1,
  test_fixture   => 'startersite';

use SylSpace::Test::App;
my $t = SylSpace::Test::App->new_app;

use Test2::V0;

$t->app->mode('production');
$t->ua->server->url('https');
$t->get_on_domain_ok('corpfin', '/auth/authenticator')
  ->status_is(200);

my $url = $t->tx->req->url->to_abs;
is $url->host, 'auth.lvh.me', 'redirected correctly';
is $url->path, '/auth/authenticator', 'to the right page';



done_testing;
