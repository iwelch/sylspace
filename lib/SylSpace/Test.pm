package SylSpace::Test;
use common::sense;

use feature ':5.20';
use feature 'signatures';
no warnings qw(experimental::signatures);

use Test2::Tools::GenTemp;
use Mojo::File qw(path curfile);
use YAML::Tiny;
use File::Copy::Recursive qw(dircopy);


=head1 NAME

SylSpace::Test - routines for testing SylSpace

=head1 SYNOPSIS

  use SylSpace::Test 
    make_test_site => 1,
    test_fixture => 'startersite';

  use Test2::V0;

  #lots of tests here

  done_testing;

=head1 DESCRIPTION

This is a helper package for testing SylSpace using standard perl tools.
It provides a hook to change certain key settings before the rest of SylSpace is initiated.

It does this by taking options when it's imported, and using that to set up the file backend for the app.

=head1 OPTIONS

SylSpace::Test provides the following import options:

=head2 make_test_site

When make_test_site is set to a truthy value, then we set
$ENV{SYLSPACE_PATH} to a temporary directory, and make the
skeleton of the file backend. This allows tests to run in a clean
and consistent environment, and to not stomp on your actual
backend.

=head2 test_fixture

If you pass in the name of a file in share/fixtures (without the
yml suffix), then this will load that into the file backend. If
you don't set make_test_site, this will load into your actual file
backend, so unless you're the script bin/load_site, you probably
also want to set make_test_site.

=cut

my $home = curfile->dirname->dirname->dirname;

sub import ($target, %opts) {
  if ($opts{make_test_site}) {

    $ENV{SYLSPACE_PATH} = gen_temp 
      'domainname=lvh.me' => '',
      'paypal.log' => '',
      'general.log' => '',
      'secrets.txt' => <<SECRETS,
hinglebinglejingle
snerbopperleestell
lotsofgarbledjunks
anothersecretof000
SECRETS
      users => { },
      courses => {},
      tmp => {},
      templates => {};
    dircopy $home->child('templates', 'equiz'), "$ENV{SYLSPACE_PATH}/templates"
  }

  if (my $fix = $opts{test_fixture}) {
    #we must load these at run time, so we can override
    #SYLSPACE_PATH if asked to
    require SylSpace::Model::Model;
    require SylSpace::Model::Webcourse;
    require SylSpace::Model::Files;

    my $path = $home->child(qw/share fixtures/, "$fix.yml");
    die "fixture file $fix.yml not found" unless $path->stat;
    my $data = YAML::Tiny->read($path)->[0];
    for my $user (@{ $data->{users} }) {
      #make the user
      my $email = delete $user->{email};
      my $type  = delete $user->{type};
      SylSpace::Model::Model::usernew($email);

      #don't make a bio if we don't have more info
      next unless keys %$user;
      SylSpace::Model::Model::biosave($email,
        { email => $email, %$user });
    }

    for my $course (@{ $data->{courses} }) {
      my $name = $course->{name};
      #create the course
      SylSpace::Model::Webcourse::_webcoursemake($name);

      #add an instructor if instructed to
      if (my $i = $course->{instructor}) {
        SylSpace::Model::Model::instructornewenroll($name, $i);
        SylSpace::Model::Model::sudo($name, $i);
        
        #save course info
        SylSpace::Model::Model::ciosave($name, $course->{info})
          if $course->{info};
          
        #save button settings
        SylSpace::Model::Model::ciobuttonsave($name, $course->{buttons})
          if $course->{buttons};

        my $msgs = $course->{messages};
        if (ref $msgs eq 'ARRAY') {
          #save messages
          for my $msg (@$msgs) {
            my $id = delete $msg->{id};
            SylSpace::Model::Model::msgsave($name, $msg, $id)
          }
        }

        my $templates = $course->{templates};
        if (ref $templates eq 'ARRAY') {
          #move over templates
          SylSpace::Model::Model::cptemplate($name, $_)
            for @$templates;
        }

        my $files = $course->{files};
        if (ref $files eq 'ARRAY') {
          for my $file (@$files) {
            my $content = $file->{content};
            $content = $home->child($file->{path})->slurp if $file->{path};
            SylSpace::Model::Files::filewritei(
              $name, $file->{name}, $content);
            SylSpace::Model::Files::filesetdue(
              $name, $file->{name}, time() + $file->{duein}) 
            if $file->{duein};
          }
        }
      }
      my @students;
      #add students if they exist
      @students = @{ $course->{students} } if $course->{students};
      SylSpace::Model::Model::userenroll($name, $_) for @students;
    }
  }
}

9005  
