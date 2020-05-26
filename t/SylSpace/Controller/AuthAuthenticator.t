use SylSpace::Test
  make_test_site => 1,
  test_fixture   => 'startersite';

use SylSpace::Test::App;
my $t = SylSpace::Test::App->new_app;

use Test2::V0;

$ENV{SYLSPACE_onlocalhost} = 0;
$t->ua->server->url('https');
$t->get_on_domain_ok('corpfin', '/auth/authenticator');

is $t->tx->req->url->to_abs->host,
  'auth.lvh.me', 'redirected correctly';



done_testing;
