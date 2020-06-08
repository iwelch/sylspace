use SylSpace::Test
  make_test_site => 1,
  test_fixture => 'startersite';

use SylSpace::Test::App;
my $t = SylSpace::Test::App->new_app;

use Test2::V0;

$t->app->routes->get('/testit' => sub {
  my $c = shift;
  $c->render(json => { name => $c->sitename, sub => $c->subdomain })
});

subtest 'testing sitename and subdomain helper' => sub {
use Data::Printer;
  $t->get_ok('/testit')
    ->status_is(200)
    ->json_is('/name' => '127.0.0.1');

  $t->get_on_domain_ok($_, '/testit')
    ->status_is(200)
    ->json_is('/sub' => $_)
    ->json_is('/name' => 'lvh.me') for '', 'auth', 'corpfin';
};

done_testing;
