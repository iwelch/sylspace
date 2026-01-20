#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::AuthGoclass;
use Mojolicious::Lite;

use SylSpace::Model::Model qw(courselistenrolled courselistnotenrolled bioiscomplete);
use SylSpace::Model::Controller qw(standard global_redirect timedelta);

################################################################

get '/auth/goclass' => sub {
  my $c = shift;

  (my $course = standard( $c )) or return global_redirect($c);

  (bioiscomplete($c->session->{uemail})) or $c->flash( message => 'You first need to complete your bio!' )->redirect_to('/auth/bioform');

  ($c->session->{expiration}) or die "you have no expiration date, ".$c->session->{uemail}."?!";

  $c->stash( timedelta => timedelta( $c->session->{expiration} ),
	     courselistenrolled => [ sort keys %{courselistenrolled($c->session->{uemail})} ],
	     email => $c->session->{uemail} );
};

get '/auth/findclass' => sub {
  my $c = shift;

  (my $course = standard( $c )) or return global_redirect($c);

  (bioiscomplete($c->session->{uemail})) or $c->flash( message => 'You first need to complete your bio!' )->redirect_to('/auth/bioform');

  ($c->session->{expiration}) or die "you have no expiration date, ".$c->session->{uemail}."?!";

  $c->stash( timedelta => timedelta( $c->session->{expiration} ),
	     courselistnotenrolled => courselistnotenrolled($c->session->{uemail}),
	     email => $c->session->{uemail} );
};



package Mojolicious::Controller {
  #NOTE- this ugly hack is because Mojolyst doesn't seem to let me
  #define helpers here, and also doesn't use this class as its
  #controller object. *sigh*
  use SylSpace::Model::Controller qw(obscure btnblock);

  use Mojo::URL;

  sub course_button_enter {
    my ($self, $course, $email) = @_;
    my $curdomainport= $self->domainport;
    
    my $enter_url = Mojo::URL->new->host("$course.$curdomainport")
      ->path('/enter');
    $enter_url->query(e => obscure join ':', time, $email, $self->session->{expiration});

    return btnblock($enter_url, 
      qq{<i class="fa fa-circle"></i> $course},
      qq{<a href="/auth/userdisroll?c=$course"><i class="fa fa-trash"></i> unenroll $course.$curdomainport</a>},
      'btn-default',
      'w' );
  }


  sub course_button_enroll {
    my ($self, $course, $subtext, $has_secret) = @_;
    my $url = $has_secret ? "/auth/userenrollform?c=$course" : "/auth/userenrollsavenopw?course=$course";
    my $icon_class = $has_secret ? 'fa-lock' : 'fa-circle-o';
    return btnblock($url, qq{<i class="fa $icon_class"></i> $course}, $subtext, 'btn-default', 'w')
  }


}

1;

################################################################

__DATA__


@@ authgoclass.html.ep

% use SylSpace::Model::Controller qw(btnblock);

%title 'superhome';
%layout 'auth';

<main>

<hr />

<h3> Enrolled Courses </h3>

  <div class="row top-buffer text-center">
    % my $has_course = @$courselistenrolled;
    % for my $course (@$courselistenrolled) {
    %== $self->course_button_enter($course, $email)
    % }
    % unless ($has_course) {
      <p class="col-xs-12 col-md-6 h2"> No courses enrolled yet. </p>
    % }

    % my $others = $has_course ? 'Other' : '';
    <%== btnblock("/auth/findclass", "$others Available Courses", '', "btn-info", 'w') %>
  </div>

  <hr />

  %= include '_course_search_bar'

%= include '_edit_user_settings'

%= include '_paypal'

</main>

@@ authfindclass.html.ep

%title 'superhome';
%layout 'auth';

<main>

<hr />

  <h3> Available Courses </h3>

  <div class="row top-buffer text-center">
    % my @notenrolled = sort keys %$courselistnotenrolled;
    % for my $course (@notenrolled) {
    %== $self->course_button_enroll($course, 'singleton', $courselistnotenrolled->{$course})
    % }
    % unless (@notenrolled) {
    <p>No courses available.</p>
    % }

  </div>

  %= include '_course_search_bar'

  <hr />

  <h3> <%= link_to 'Back to Enrolled Courses' => 'authgoclass' %> </h3>

%= include '_edit_user_settings'
%= include '_paypal'

</main>

@@ _course_search_bar.html.ep

    <form name="selectcourse" method="get" action="/auth/userenrollform" class="form"> 
      <div class="input-group">
        <span class="input-group-addon">Course Name: <i class="fa fa-square"></i></span>
        <input class="form-control" placeholder="coursename, e.g., welch-mfe101-2017.ucla" name="c" type="text" required />
      </div>
      <div class="input-group">
        <button class="btn btn-default" type="submit" value="submit">Select a course by its full name</button>
      </div>
    </form>

@@ _edit_user_settings.html.ep

% use SylSpace::Model::Controller qw(btnblock);

<h3> Change Auto-Logout Time </h3>

  <p>Currently, you are set to be logged out in <span><%= ((($self->session->{expiration})||0)-time())." seconds" %>, which is <%= $timedelta %>.</span></p>

   <div class="row top-buffer text-center">
     <%== btnblock("settimeout?tm=1", '<i class="fa fa-clock-o"></i> 1 day', 'reasonably safe', 'btn-default', 'w') %>
     <%== btnblock("settimeout?tm=7", '<i class="fa fa-clock-o"></i> 1 week', 'quite unsafe', 'btn-default', 'w') %>
  </div>

   <div class="row top-buffer text-center">
     <%== btnblock("settimeout?tm=90", '<i class="fa fa-clock-o"></i> 3 mos', 'better be your own computer', 'btn-default', 'w') %>
     <%== btnblock("/logout", '<i class="fa fa-sign-out"></i> Logout', 'from authentication', "btn-danger", 'w') %>
  </div>

  <hr />

<h3> Change Biographical Information and Settings, and Add Passkeys </h3>

   <div class="row top-buffer text-center">
     <div class="col-xs-12 col-md-4">
       <a class="btn btn-block btn-default" href="/auth/bioform">
         <h3><i class="fa fa-user"></i> <%= $self->session->{uemail} %></h3>
       </a>
       <p>Change My Biographical Information and Add Passkeys</p>
     </div>
   </div>


@@ _paypal.html.ep
% use SylSpace::Model::Utils qw( _encodeencrypt _burpapp );
% my $raw = time()."\t".$self->session->{uemail};
% my $uemencrypt= _encodeencrypt( $raw );
% _burpapp( undef, "$raw|$uemencrypt" );


  % if (has_oauth) {

   <h3> Donate and Confirm Identity  </h3>

   <div class="row top-buffer text-center">

     <div class="col-xs-12 col-md-6 text-center">
		<form action="https://www.paypal.com/cgi-bin/webscr" method="post" target="_top">
			<input type="hidden" name="cmd" value="_s-xclick" >
			<input type="hidden" name="hosted_button_id" value="A654PPKTNDSPA" >
  			<input type="hidden" name="custom" value="<%= $uemencrypt %>" >
			<table>
				<tr><td><input type="hidden" name="on0" value="Select Price">Select Donation</td></tr>
				<tr><td><select name="os0" class="form-control">
					<option value="Option 4">Option 4 $0.01 USD</option>
					<option value="Option 1">Option 1 $1.00 USD</option>
					<option value="Option 2">Option 2 $5.00 USD</option>
					<option value="Option 3">Option 3 $10.00 USD</option>
				</select> </td></tr>
				<tr>
					<td>
			<input type="hidden" name="currency_code" value="USD">
			<input type="image" role="button" class="btn btn-default" src="https://www.paypalobjects.com/en_US/i/btn/btn_buynowCC_LG.gif" border="0" name="submit" alt="PayPal">
			<img alt="" border="0" src="https://www.paypalobjects.com/en_US/i/scr/pixel.gif" width="1" height="1">
					</td>
				</tr>
			</table>
		</form>
	</div> <!-- col xs-12 -->
	</div> <!-- row -->
  % } else { 

       <p> Paypal further authentication options omitted in local test mode without OAuth. </p>

  % }

   </div>
