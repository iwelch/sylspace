package SylSpace::Test;
use common::sense;

use feature ':5.20';
use feature 'signatures';
no warnings qw(experimental::signatures);

use Test2::Tools::GenTemp;
sub import ($target, %opts) {
  if ($opts{make_test_site}) {
  $ENV{SYLSPACE_PATH} = gen_temp 
    'domainname=lvh.me' => '',
    'paypal.log' => '',
    'general.log' => '',
    'secrets.txt' => 'hinglebinglejingle',
    users => {},
    courses => {},
    tmp => {},
    templates => { 
      starters => {}
    };
  }
}

9005  
