package SylSpace::Controller::Privacy;
use Mojolicious::Lite;
use SylSpace::Model::Model qw(isinstructor);

sub background_depends {
  my $c = shift;
  my $course = $c->subdomain;
  my $letter = 'a';
  if ($course && $course ne 'auth') {
    $letter = 's';
    my $email = $c->session->{uemail};
    $letter = 'i' if $email && eval { isinstructor($course, $email) }
  } 
  $c->render( bgcolor => $ENV{"SYLSPACE_site${letter}color"},
    fgcolor => $ENV{"SYLSPACE_jumbo${letter}color"} );
}

get '/privacy' => { homeurl => '/privacy' } => \&background_depends, 'privacy_policy';

get '/tos' => { homeurl => '/tos' } => \&background_depends, 'terms_of_service';




__DATA__
@@ privacy_policy.html.ep
% title 'Privacy Policy';
% layout 'sylspace';

<main>
  <p> We are storing personal data for our registered users,
  primarily for purposes of sharing this information with
  instructors (and some other students) in a clear fashion.  (The
  data is marked for users when it is public vs. when it is
  private.)  We also use it to improve our site.  We are not sharing
  data with third parties, least of all for commercial or marketing
  purposes.  We may use the data for academic research purposes in
  the future.  </p>
</main>

@@ terms_of_service.html.ep
% title 'Terms of Service';
% layout 'sylspace';

<main>
  <p> We do not charge for use or content.  Thus, we cannot offer
  any guarantees or warranties of any kind to users of our
  website, especially a guarantee that our site cannot be
  illegally breached by hackers.  We reserve the right to ban
  users for posting illegal or offensive content---or simply by
  our own sudden whim.  Use this site at your own risk. </p>
</main>
