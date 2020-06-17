use SylSpace::Test
  make_test_site => 1,
  test_fixture   => 'startersite';

use SylSpace::Test::App;
my $t = SylSpace::Test::App->new_app;

use Test2::V0;

$t->get_on_domain_ok('auth','/login', email => 'student@gmail.com')
  ->status_is(200, 'logged in alright');

$t->get_on_domain_ok('auth', '/auth/goclass')
  ->status_is(200, 'got class list')
  ->element_count_is('.fa-circle', 1, 'lists our one class');

$t->get_on_domain_ok('auth', '/auth/findclass')
  ->status_is(200, 'got new classes list')
  ->element_count_is('.fa-lock', 1);

$t->get_on_domain_ok('auth', '/auth/userenrollform',
  c => 'syllabus-test.lvh.me')
  ->status_is(200)
  ->attr_like('input#secret', placeholder => qr/instructor provided/);

$t->post_on_domain_ok('auth', '/auth/userenrollsave', form => {
    course => 'syllabus-test',
    c      => 'syllabus-test',
    secret => 'learn'
  })
  ->status_is(200)
  ->element_count_is('.fa-circle', 2, 'signed up for 2 classes');



done_testing;
