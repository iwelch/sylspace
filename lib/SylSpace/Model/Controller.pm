#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Model::Controller;

use base 'Exporter';
@ISA = qw(Exporter);

our @EXPORT_OK =qw(  standard global_redirect global_redirectmsg
		     timedelta epochof epochtwo timezones
		     btn btnsubmit btnblock btnxs
		     msghash2string ifilehash2table
		     drawform drawmore fileuploadform displaylog mkdatatable
		     webbrowser
		     obscure unobscure
);

use strict;
use warnings;
use common::sense;
use utf8;
use warnings FATAL => qw{ uninitialized };
use autodie;

use feature ':5.20';
use feature 'signatures';
no warnings qw(experimental::signatures);

use Data::Dumper;
use Devel::StackTrace;

################################################################

=pod

=head1 Title

  Controller.pm --- routines used repeatedly in the controller.

=head1 Description

  this code must *not* be dependent on any backend model code.

  it contains common utility routines, and some longer routines
  that are used in multiple url's.

=head1 Versions

  0.0: Sat Apr  1 10:55:38 2017

=cut

################################################################
## basic routines used by most webpages
################################################################

my $global_redirecturl;
my $global_message;

## standard() should start every webpage.  it makes sure that we have
## a session uemail and expiration, and redirects nonsensible
## subdomains (course names) to /auth

sub standard {
  my $c= shift;

  my $cururl= $c->req->url;  ## /auth/dosome
  (defined($cururl)) or die "cannot ascertain the current url via c->req->url\n";


  my $domain= $cururl->domainport;  ## mfe.welch.$ENV{'SYLSPACE_sitename'}:3000
  my $course= $cururl->subdomain; ## mfe.welch

  $cururl =~ s{\?.*}{}; ## strip any parameters

  #or $c->webbrowser()
  ((defined($c->browser->{"browser"})) && ($c->browser->{"browser"} =~ /chrome/i) && (($ENV{'SYLSPACE_onlocalhost'})))
    and die "Chrome does not work with localhost (syllabus.test), because it handles localhost domains differently.\n\nPlease use firefox or some other browser.";

  sub retredirect { $global_redirecturl= $_[0]; $global_message= $_[1] || ""; return; }

  my $reloginurl="http://auth.$domain/auth/index";

  if ($course eq 'auth') {
    ## already in http://auth.$domain/...  --> never redirect, always allowed
    my @authallowedurls= qw(/auth/index /auth /logout /auth/logout /auth/facebook
			/auth/localverify /auth/userenrollsave /auth/userenrollsave
			/auth/biosave /auth/settimeout /auth/dani);
    foreach my $au (@authallowedurls) {
      ($cururl =~ m{^$au}) and return 'auth';
    }
  }

  defined($c->session->{uemail}) or return retredirect($reloginurl, "no identity yet");

  if ($course eq 'auth') {
    ($cururl eq '/auth/goclass') and return 'auth';  ## also now ok; will not redirect
    return retredirect($reloginurl, "unknown url. start over");  ## no other urls on aux are ok
  }

  ## anything else requesting an auth page is redirected to the aux website
  ($cururl =~ m{^/auth/goclass}) and return retredirect("http://auth.$domain/auth/goclass", "/auth requests channel back ");
  ($cururl =~ m{^/auth/}) and return retredirect($reloginurl, "/auth requests channel back ");

  ($course =~ /\w/) or return retredirect($reloginurl, "the base domain is not defined");
  ($course =~ /^www\./) and return retredirect($reloginurl, "the www domain (on $course) is not defined");


  (time() > $c->session->{expiration}) and return retredirect($reloginurl, "your session has expired.");
  return $course;
}


## we use global variables because M cannot redirect deep in
## the code.  so we set these global variables and return undef

sub global_redirectmsg {
  my $c= shift;
  return $global_message;
}

sub global_redirect {
  my $c= shift;
  $c->flash(message => $global_message);

  return $c->redirect_to($global_redirecturl);
}


################################################################

## http://a.b.c.d/e/f?g=h&i=j

## $self->req->url
##   ->to_abs:   http://a.b.c.d:1/e/f?g=h&i=j#k
##   ->fragment: k
##   ->host: a.b.c.d
##   ->port: 1
##   ->host_port: a.b.c.d:1
##   ->scheme: http
##   ->url->parse($)->host: a.b.c.d:1
##   ->url->parse($)->path: /e/f
##   ->path_query: /e/f?g=h&i=j ?#k

## not used userinfo for n@a.b.c.d
##   ->to_string: omits userinfo

sub _subdomain( $c ) {
  return $c->req->url->subdomain;
}

sub _domainport( $c ) {
  return $c->req->url->domainport;
}


################################################################

=pod

=head2 Time related Functions

=cut

################################################################

sub StackTracePrint {
  my $trace = Devel::StackTrace->new;
  # from bottom (least recent) of stack to top.
  print "\n";
  while ( my $frame = $trace->next_frame ) {
    ($frame->subroutine =~ /SylSpace::Model::Controller::StackTracePrint/) and next;
    ($frame->subroutine =~ /^Devel/) and next;
    ($frame->subroutine =~ /^Stack::Mojo/) and last;
    ($frame->subroutine =~ /^Mojo/) and last;
    print "\t--> ", $frame->as_string, "\n";
  }
  print "\n";
}

## a nice English version of how much time is left
sub timedelta {
  ($_[0]) or StackTracePrint();
  ($_[0]) or die "weird call without time to timedelta from ".((caller(1))[3]);

  my $x= ($_[1]||time()) - ($_[0]);
  sub tdt {
    my $ax= abs($_[0]);
    sub mm { return $_[0]." $_[1]".(($_[0]>1)?"s":""); }
    ($ax<60) and return mm($ax, "sec");
      ($ax<60*60) and return mm(int($ax/60), "min");
    ($ax<60*60*24) and return mm(int($ax/60/60*1.01), "hour");
    ($ax<60*60*24*7) and return mm(int($ax/60/60/24*1.01), "day");
    ($ax<60*60*24*31) and return mm(int($ax/60/60/24/7*1.01), "week");
    ($ax<60*60*24*365) and return mm(int($ax/60/60/24/30*1.01), "month");
    return mm(int($ax/60/60/24/365), "year");
  }
  ($x<0) and return "in ".tdt($x);
  return tdt($x)." ago";
}


################
## calculate the time difference between server GM and local time

sub _tziofserver {
  my $off_h=1;
  my @local=(localtime(time+$off_h*60*60));
  my @gmt=(gmtime(time+$off_h*60*60));
  return $gmt[2]-$local[2] + ($gmt[5] <=> $local[5]
			      ||
			      $gmt[7] <=> $local[7])*24;
}



################
## html date picker returns a date and time, but we want to store
## everything in epoch

sub epochof {
  my ($d1,$d2,$tzi)=@_;
  (defined($tzi)) or die "please set timezone";
  $d2 =~ s/%3A/:/g; ## if any
  ($d1 =~ /[12]\d\d\d\-[01]\d-\d\d/) or die "bad yyyy-mm-dd $d1\n";
  ($d2 =~ /[012]\d:[0-5]\d/) or die "bad hh:mm $d2\n";

  # ($tzi == (-7)) or die "wtf.  you should be in the -7 timezone, not $tzi";
  # $tzi*= (-1);  ## quoted as the opposite. gmt - local

  $tzi= sprintf("%s%02d:00", ($tzi>0)?"+":"-", abs($tzi));
  ($tzi =~ /[+-][01]\d:\d0/) or die "bad time zone int offset $tzi";
  my $p="${d1}T${d2}:00$tzi";

  my $e=Mojo::Date->new($p)->epoch;
  (defined($e)) or die "internal epochof conversion error from $d1, $d2, $tzi";
  return $e;
}


################
## returns an html table with four different versions of epoch time

sub _epochfour( $epoch, $tzi ) {
  ($epoch == 0) and return "no date yet";
  ($epoch >= 140000000) or die "nonsensible $epoch\n";

  my $duegmt=gmtime($epoch);
  my $dueserver=localtime($epoch);  ## GMT-07:00 DST
  my $dueuser= defined($tzi) ? gmtime($epoch+$tzi*60*60) : "n/a";
  my $gmtadd= (defined($tzi)) ? " GMT $tzi:00" : "";

  my $serveruser= ($dueuser eq $dueserver) ? 
    "<tr> <td>Server/User:&nbsp;</td> <td> $dueserver $gmtadd</td></tr>\n" :
    "<tr> <td>Server:&nbsp;</td> <td> $dueserver</td></tr>\n".
    "<tr> <td>User: </td> <td> $dueuser  $gmtadd</td> </tr>";

  return
    "<table style=\"font-family:monospace\">".
    "<tr> <td>Epoch: </td> <td><span class=\"epoch14\">$epoch</span></td> </tr>\n".
    "<tr> <td>GMT: </td> <td> $duegmt</td></tr>\n".
    $serveruser.
    "<tr> <td>Relative:&nbsp; </td> <td> ".timedelta( $epoch )."</td> </tr>".
    "</table>";
}


sub epochtwo( $epoch ) {
  qq(<span class="epoch0">$epoch</span> ).timedelta($epoch);
}


################################################################

=pod

=head2 Button-Related Drawing

=cut

################################################################

sub btn( $url, $text, $btntypes="btn-default", $extra="" ) {
  return qq(<a href="$url" class="btn $btntypes" $extra>$text</a>); }

sub btnsubmit {
  $_[3].= qq( type="submit" value="submit" ); return btn(@_); }

sub btnblock($url, $text, $belowtext="", $btntypes="btn-default", $textlength=undef) {
  if ($btntypes =~ 1) { $btntypes="btn-default", $textlength='n'; }
  my @w= ( 1, 2, 4, 4 );
  my $h= 'h2';
  if (defined($textlength)) {
    if ($textlength eq 'w') { @w = ( 1, 1, 2, 2 ); $h='h3'; }
    elsif ($textlength eq 'sw') { @w = ( 1, 1, 2, 2 ); $h='h4'; }
    elsif ($textlength eq 'n') { @w = ( 2, 2, 4, 4 ); }
    else { die "textlength argument should not be $textlength, but n or w\n"; }
  }
  foreach (@w) { $_ = 12/$_; }
  $belowtext= "<p>$belowtext</p>";


  ## Since grid classes apply to devices with screen widths greater than or equal to the breakpoint sizes (unless overridden by grid classes targeting larger screens), `class="col-xs-12 col-sm-12 col-md-6 col-lg-6"` is redundant and can be simplified to `class="col-xs-12 col-md-6"`
  return qq(<div class="col-xs-$w[0] col-md-$w[2]">).
    btn($url, "<$h>$text</$h>", "btn btn-block $btntypes")
    .$belowtext
    .'</div>';


  ## for short button text, we can do 2 for xs, 4 for sm 
  ## for normal button text, we want 1 for xs, 2 for sm, 4 for md and lg

  return qq(<div class="col-xs-$w[0] col-sm-$w[1] col-md-$w[2] col-lg-$w[3]">).
    btn($url, "<$h>$text</$h>", "btn btn-block $btntypes")
    .$belowtext
    .'</div>';
}




################################################################

=pod

=head2 Functions used by 2-3 URLs

=cut

################################################################

## use this if you want to make a table sortable
sub mkdatatable {
  return '<script type="text/javascript" class="init">
    $(document).ready(function() {
       $(\'#'.$_[0].'\').DataTable( { "paging":false, "info":false  } );
    } );
  </script>'; }


################
## used by all file-related centers (hw, equiz, file)

sub fileuploadform {
return '
   <form action="/uploadsave" id="uploadform" method="post" enctype="multipart/form-data" style="display:block">
     <label for="idupload">Upload A New File: </label>
     <input type="file" name="file" id="idupload" style="display:inline"  >
   </form>

   <script>
      document.getElementById("idupload").onchange = function() {
         document.getElementById("uploadform").submit();
      }
   </script>

  <table>
  <tr> <td>
  <ul style="margin-left:5em;font-size:smaller">
  <li> any file starting with <tt>hw</tt> is considered to be a <a href="/instructor/hwcenter">homework</a>,</li>
  <li> any file ending with <tt>.equiz</tt> is considered to be an <a href="/instructor/equizcenter">equiz</a>,</li>
  <li> and any other file (e.g., <tt>syllabus.html</tt>) is considered just a <a href="/instructor/filecenter">file</a>.</li>
  </ul> </td>
  <td> <ul style="margin-left:5em;font-size:smaller">
  <li> note that you may have to switch center to see your uploaded file(s).<br>for example, if you upload an .equiz file into the hwcenter,<br />it will not appear in the (hwcenter) filelist, but in the equizcenter list!</li> 
  </ul> </td> </tr> </table>
 ';
}


################
## used by both student and instructor, this draws all messages at the
## top of their home page

sub msghash2string( $msgptr, $msgurlback="", $listofread=undef, $tzformat=undef ) {
  (defined($msgptr)) or die "internal error";

  my %listofread;
  if ($listofread) {
    (ref($listofread) eq 'ARRAY') or die "bad input---we have a ".ref($listofread)."\n".Dumper($listofread);
    foreach (@$listofread) { $listofread{$_}=1; }
  }

  my $msgstring= '<div class="msgarea">';

  foreach (@$msgptr) {
    my $donotshowmarkreadagain="";
    if ($listofread) {
      $donotshowmarkreadagain= qq(
          <a href="$msgurlback?msgid=$_->{msgid}" class="btn btn-default btn-xs" style="font-size:x-small;color:black" > X do not show again</a>
);
    } else {
      $donotshowmarkreadagain = defined($listofread{$_->{msgid}}) ? "" : <<EOS;
          <a href="$msgurlback?msgid=$_->{msgid}" class="btn btn-default btn-xs" style="font-size:x-small;color:black" > X do not show again</a>
EOS
    }

    my $priorityclass= ($_->{priority} > 5) ? " priorityhigh" : ($_->{priority} < 5) ? " prioritylow" : "";

    my $epoch= (defined($tzformat)) ? _epochfour($_->{time}, $tzformat) : epochtwo($_->{time});
    $msgstring .= <<EOM;
  <dl class="dl-horizontal $priorityclass" id="$_->{msgid}">
    <dt>msgid</dt> <dd class="msgid-msgid ">$_->{msgid} $donotshowmarkreadagain</dd>
    <dt>date</dt> <dd class="msgid-date">$epoch</dd>
    <dt>subject</dt> <dd class="msgid-subject" > $_->{subject}</dd>
    <dt></dt> <dd class="msgid-msg"> $_->{body}</dd>
  </dl>
EOM
  }
  return $msgstring .= "\n</div>\n";
}



################
## used by course (cio) and bio settings, this draws the html form

sub drawform {
  my ($readschema, $ciobio)= @_;

  my $rs= "";
  foreach (@{$_[0]}) {
    my @name=keys(%{$_}); my $name= $name[0];
    my %f= %{$_->{$name}};
    ($name eq 'defaults') and next;
    ($name eq 'email') and next;
    my $hstarrequired= ($f{required}) ? '*' : ' ';
    my $hpublic=($f{public}) ? '[public]' : '[undisclosed]';
    my $hreadonly= ($f{readonly}) ? 'readonly' : '';
    my $hrequired= ($f{required}) ? 'required' : '';
    my $hhtmltype= ($f{htmltype}) ? "type=\"$f{htmltype}\"" : '';
    my $hpattern= ($f{regex}) ? "pattern=\"$f{regex}\"" : "";
    my $hmaxsize= ($f{maxsize}) ? "maxsize=\"$f{maxsize}\"" : "";
    my $hvalue= ($f{value}) ? "value=\"$f{value}\"" : "";
    my $hplaceholder= ($f{placeholder}) ? "placeholder=\"$f{placeholder}\"" : "";

    ((defined($ciobio)) && (defined($ciobio->{$name}))) and $hvalue="value=\"$ciobio->{$name}\"";  ## override default with the preexisting value

    $rs.= qq(
	<div class="form-group">
	  <label class="col-sm-2 control-label col-sm-2" for="$name">${name}$hstarrequired</label>
	  <div class="col-sm-6">$hpublic
		<input class="form-control foo" id="$name" name="$name" $hhtmltype $hmaxsize $hvalue $hplaceholder $hrequired $hreadonly $hpattern />
	  </div>
        </div>
       );
  }
  return $rs;
}


################
## this draws the "more" screens for homeworks, equizzes, and files

sub drawmore($sfilename, $centertype, $actionchoices, $allfiledetails, $tzi, $webbrowser="") {

  my $detail;
  foreach (@{$allfiledetails}) {
    ## we need to ferret the creation and due times
    if ($_ -> {sfilename} eq $sfilename) { $detail= $_; last; }
  }

  my $fname= $detail->{sfilename};

  my $achoices= actionchoices( $actionchoices, $fname );

  my $changedtime= _epochfour( $detail->{mtime}||0, $tzi );
  my $delbutton= btn("filedelete?f=$fname", 'delete', 'btn-xs btn-danger');
  my $backbutton= btn($centertype."center", "back to ${centertype}center", 'btn-xs btn-default');

  use POSIX qw(strftime);
  my $dueyyyymmdd="";  my $duehhmm="23:59";
  if ($detail->{duetime}) {
    $dueyyyymmdd=  strftime('%Y-%m-%d', localtime($detail->{duetime}));
    $duehhmm=  strftime('%H:%M', localtime($detail->{duetime}));
  }
  my $duetimefour= _epochfour( $detail->{duetime}||0, $tzi );

  $webbrowser = ((defined($webbrowser)) and ($webbrowser eq 'safari')) ? qq(<br />safari's date selector is broken.  please complain to apple and use a better browser<br />until then, use mm/dd/yyyy) : '';

  my $sixmobutton= "<p style=\"padding:1em\"> or <span style=\"padding:2ex\">".btn("filesetdue?f=$fname&amp;dueepoch=".(time()+24*3600*180), "publish for 6 Months", 'btn-default')."</span>".
     " or <span style=\"padding:2ex\">".btn("filesetdue?f=$fname&amp;dueepoch=".(time()-2), "unpublish", 'btn-default')."</span></p>";

  my $v= <<EOT;
  <table class="table">
    <thead> <tr> <th> variable </th> <th> value </th> </tr> </thead>
    <tbody>
	<tr> <th> file name </th> <td> $fname </td> </tr>
	<tr> <th> file size</th> <td> $detail->{filelength} bytes </td> </tr>
	<tr> <th> changed </th> <td> $changedtime </td> </tr>
	<tr> <th> action </th> <td> $achoices </td> </tr>
	<tr> <th> visible until </th> <td> $duetimefour
			<p>
			<form method="get" action="filesetdue?f=$fname" class="form-inline">
			<input type="hidden" name="f" value="$fname" />
			User Time: <input type="date" id="duedate" name="duedate" placeholder="yyyy-mm-dd" value="$dueyyyymmdd" onblur="submit();" />
			<input type="time" id="duetime" name="duetime" value="$duehhmm" />
			<input type="submit" id="submit" value="update" class="btn btn-xs btn-default" />
                   $webbrowser
			</form>
		$sixmobutton
	   </td> </tr>
	<tr> <th> delete </th> <td> $delbutton </td> </tr>
	<tr> <td colspan="2"> $backbutton </td> </tr>
    </tbody>
  </table>
EOT

}

################
## used by "*more" for inspection of files

sub ifilehash2table( $filehashptr, $actionchoices, $type, $tzi ) {
  defined($filehashptr) or return "";
  my $filestring= '';
  my $counter=0;

  foreach (@$filehashptr) {
    ++$counter;

    (defined($_->{filelength})) or next;  ## this is really an error, like a symlink to something undefined
    my $fq= "f=$_->{sfilename}";

    my $publish= ($_->{duetime}>time()) ?
      qq(<a href="${type}more?$fq"> ).epochtwo($_->{duetime}).'</a> '. btn("filesetdue?$fq&amp;dueepoch=".(time()-2), "unpub", 'btn-info btn-xs')
      :
      btn("filesetdue?$fq&amp;dueepoch=".(time()+24*3600*180), "publish", 'btn-primary btn-xs');

    my $achoices= actionchoices( $actionchoices, $_->{sfilename} );

    my $thismdfddate= epochtwo($_->{mtime}||1);
    $filestring .= qq(
    <tr class="published">
	<td class="c">$counter</td>
	<td class="c"> $publish </td>
	<td> <a href="${type}more?$fq">$_->{sfilename}</a> </td>
    <meta http-equiv="X-UA-Compatible" content="IE=edge" />
	<td class="int" style="text-align:right"> $_->{filelength} </td>
	<td class="c"> $thismdfddate </td>
        <td class="c"> $achoices </td>
	<td class="c"> <a href="${type}more?$fq" class="btn btn-default btn-xs">more</a> </td>
     </tr>)
  }

  return mkdatatable('taskbrowser').<<EOT;

  <table id="taskbrowser" class="table">
    <thead>
      <tr>
        <th class="c">#</th><th class="c">public until</th><th class="c">$type name</th><th class="c">bytes</th><th class="c">modfd</th><th class="c">actions</th> <th class="c">more</th>
     </tr>
    </thead>

    <tbody>
       $filestring
    </tbody>
  </table>
  <form action="/uploadsave" method="post" class="dropzone" id="dropzoneform" enctype="multipart/form-data">
  </form>

  <script type="text/javascript">
    	Dropzone.options.dropzoneform = {				                
		init: function() {
			uploadMultiple: true,
			this.on("queuecomplete", function() {				
				console.log("queue completed.");
				window.location.reload(true);
		     	 });
			
			this.on("success", function(file, response) {
				console.log(file.name + " files successfully uploaded.");
			});

			this.on("error", function(file, errorMessage) {
				console.log(errorMessage);
			});
		}
	};
  </script>

EOT
}

sub actionchoices( $actionchoices, $fname ) {
  my $selector= {
		 equizrun => btn("/equizrender?f=$fname", 'run', 'btn-xs btn-default'),
		 view => btn("view?f=$fname", 'view', 'btn-xs btn-default'),
		 download => btn("download?f=$fname", 'download', 'btn-xs btn-default'),
		 edit => btn("edit?f=$fname", 'edit', 'btn-xs btn-default') };

  my $achoices=""; foreach (@$actionchoices) { $achoices.= " ".$selector->{$_}; }
  return $achoices;
}



################
## used for both tweeting and security logs, displays a nice
## html version of a log file.

sub displaylog( $logptr ) {

  my $s="";
  foreach (split(/\n/, $logptr)) {
    my ($ip, $epoch, $gmt, $who, $what)=split(/\t/,$_);
    $s.= "<tr> <td>$ip</td> <td>".epochtwo($epoch)."</td> <td> $gmt </td> <td>$who</td> <td>$what</td> </tr>";
  };

  return mkdatatable('seclogbrowser').<<LOGT;
   <table class="table" id="seclogbrowser">
      <thead> <tr> <th>IP</th> <th> Epoch </th> <th> GMT </th> <th> Who </th> <th> What </th> </tr> </thead>
      <tbody>
       $s
     </tbody>
   </table>
LOGT
}

################################################################

use Crypt::CBC;
use Crypt::DES;

my $simplesecret= (-e "/usr/local/var/lib/dbus/machine-id") ? "/usr/local/var/lib/dbus/machine-id" : "/etc/machine-id";

sub obscure {
  my $message= shift;
  my $cipherhandle = Crypt::CBC->new( -key => $simplesecret, -ciper => 'Blowfish', -salt => '12312523' );
  my $secretmessage = $cipherhandle->encrypt($message);
  $secretmessage= unpack("H*", $secretmessage);
  return $secretmessage;
}

sub unobscure {
  my $secretmessage= shift;
  my $cipherhandle = Crypt::CBC->new( -key => $simplesecret, -ciper => 'Blowfish', -salt => '12312523' );
  $secretmessage= pack("H*", $secretmessage);
  $secretmessage= $cipherhandle->decrypt($secretmessage);
  return $secretmessage;
}

################################################################
sub webbrowser {
  my $self= shift;
  return $self->browser->{browser};
  # use HTTP::BrowserDetect;
  # my $ua = HTTP::BrowserDetect->new($user_agent_string);
  # my $browser= ($ua->browser_string);
}


1;
