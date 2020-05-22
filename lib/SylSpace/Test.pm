package SylSpace::Test;
use common::sense;

use feature ':5.20';
use feature 'signatures';
no warnings qw(experimental::signatures);

use Test2::Tools::GenTemp;
use Mojo::File qw(path);
use YAML::Tiny;

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
      templates => { 
        starters => {
          'finance.equiz' => 
            path('templates/equiz/starters/finance.equiz')->slurp
        }
      }
  }

  if (my $fix = $opts{test_fixture}) {
    #we must load these dynamically, so we can override
    #SYLSPACE_PATH if asked to
    require SylSpace::Model::Model;
    require SylSpace::Model::Webcourse;

    my $path = path('share/fixtures')->child("$fix.yml");
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
      #create the course
      SylSpace::Model::Webcourse::_webcoursemake($course->{name});

      my $i;
      #add an instructor if instructed to
      SylSpace::Model::Model::instructornewenroll($course->{name}, $i)
        if $i = $course->{instructor};
      my @students;
      @students = @{ $course->{students} } if $course->{students};
      #ditto for students
      SylSpace::Model::Model::userenroll($course->{name}, $_)
        for @students
    }
  }
}

9005  
