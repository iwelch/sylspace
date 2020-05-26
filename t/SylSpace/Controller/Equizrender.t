use SylSpace::Test
  make_test_site => 1,
  test_fixture   => 'messysite';

use Test2::V0;
use SylSpace::Test::App;

my $t = SylSpace::Test::App->new_app;

$t->get_on_domain_ok('auth', '/login', email => 'instructor@gmail.com')
  ->status_is(200);

$t->get_on_domain_ok('mfe.welch', '/instructor/cptemplate',
  templatename => 'starters')
  ->status_is(200, 'copied the equiz templates');

my $port = $t->ua->server->url->port;
subtest 'Render quiz on http' => sub {
  $t->get_on_domain_ok('mfe.welch', '/equizrender', f => 'finance.equiz')
    ->status_is(200)
    ->element_exists('div.equiz', 'equiz div is there')
    ->element_exists('div.qstn', 'at least one question')
    ->element_exists('.qstn input[type="hidden"]',
        'got those hidden inputs')
    ->element_exists(
      qq{form[action="http://mfe.welch.lvh.me:$port/equizgrade"]},
    'got the right grade link');
};

subtest 'Render quiz on https' => sub {
  $t->ua->server->url('https');
  $t->get_on_domain_ok('mfe.welch', '/equizrender', f => 'finance.equiz')
    ->status_is(200)
    ->element_exists(
      qq{form[action="https://mfe.welch.lvh.me:$port/equizgrade"]},
    'got the right grade link');
};
$t->ua->server->url('http');

done_testing;
