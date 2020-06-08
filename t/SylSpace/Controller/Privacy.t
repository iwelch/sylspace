use SylSpace::Test
  make_test_site => 1,
  test_fixture => 'startersite';

use SylSpace::Test::App;
my $t = SylSpace::Test::App->new_app;

use Test2::V0;
my %colors = map { ( $_ => $ENV{"SYLSPACE_jumbo${_}color"} ) } qw/i a s/;

$t->get_on_domain_ok('', '/tos')
  ->element_exists(".jumbotron[style*=$colors{a}]");

$t->get_on_domain_ok('auth', '/tos')
  ->element_exists(".jumbotron[style*=$colors{a}]");

$t->get_on_domain_ok('corpfin', '/privacy')
  ->element_exists(".jumbotron[style*=$colors{s}]");

$t->get_on_domain_ok('auth','/login', email => 'ivo.welch@gmail.com');

$t->get_on_domain_ok('corpfin', '/privacy')
  ->element_exists(".jumbotron[style*=$colors{i}]");

done_testing;
