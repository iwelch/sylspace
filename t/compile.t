use SylSpace::Test
  make_test_site => 1;
use Mojo::File qw(curfile);
use Test2::V0;

#this is effectively a syntax check on all of the files in the
#SylSpace::Controller namespace, necessary b/c Mojolyst passes
#over files silently when there are bugs

my $pages = curfile->dirname->sibling(qw( lib SylSpace Controller ))
  ->list;

$pages->map( sub {
  require $_
});

ok 1, 'no death on requiring';

done_testing;
