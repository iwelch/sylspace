use SylSpace::Test
  make_test_site => 1,
  test_fixture   => 'messysite';

use SylSpace::Test::App;
my $t = SylSpace::Test::App->new_app;

use Test2::V0;


subtest 'Death without login on auth domain' => sub {
  $t->get_on_domain_ok('auth', '/auth/goclass')
    ->status_is(500);
};

subtest 'Normal redirect on other domains' => sub {
  $t->get_on_domain_ok('corpfin', '/auth/goclass')
    ->status_is(200);
};

subtest 'Redirect to testsetuser on localhost' => sub {
  $t->get_ok('/auth/goclass')
    ->status_is(200)
    ->text_like('#userlist li', qr/make yourself/i)
    ->text_like('#userlist li a', qr'instructor@gmail.com')
    ->element_exists(
      '#userlist li a[href="/login?email=instructor@gmail.com"]');
};

subtest 'Logging in, getting redirected to class list' => sub {
  $t->get_on_domain_ok('auth','/login', email => 'student1@gmail.com')
    ->status_is(200, 'logged in alright');
};

#TODO- test that we can sign up for a course, and then test how
#those buttons come around


done_testing;
