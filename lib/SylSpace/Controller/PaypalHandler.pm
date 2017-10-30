#!/usr/bin/perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::PaypalHandler;

use Mojolicious::Lite;
use lib qw(.. ../..);		## make syntax checking easier

use SylSpace::Model::Model qw(paypallog);

use LWP::UserAgent 6;  ## what is the 6 here?
use Email::Sender::Simple 'sendmail';
use Email::Sender::Transport::SMTP::TLS;
use Email::Simple::Creator;


use strict;

################
## unfortunately, this really does not have access to $c->session.  it is called session/stateless.

post  '/paypalreturndata' => sub {
  my $c = shift;

  # (-d "/var/paypal/") or die "please ask the site to create the /var/paypal directory first.\n";

  # read post from PayPal system and add 'cmd'
  my $query = $c->req->params;	
  my $qs = "cmd=_notify-validate&".$query;
  $c->rendered(200);

  # post back to PayPal system to validate
  my $ua = new LWP::UserAgent;
  # Produciton URL
  my $req = HTTP::Request->new('POST', 'https://ipnpb.paypal.com/cgi-bin/webscr');
  # Sandbox URL
  #my $req = HTTP::Request->new('POST', 'https://ipnpb.sandbox.paypal.com/cgi-bin/webscr');
  $req->content_type('application/x-www-form-urlencoded');
  $req->header(Host => 'www.paypal.com');
  $req->content($qs);
  my $res = $ua->request($req);

  if ($res->is_error) {
    # HTTP error
    _log_paypal_error($res, $c->session->{uemail}||"noemail\@gmail.com", $c->tx->remote_address, $c->req->headers->referrer);
  } elsif ($res->content eq 'VERIFIED') {
    # check the $payment_status=Completed
    # check that $txn_id has not been previously processed
    # check that $receiver_email is your Primary PayPal email
    # check that $payment_amount/$payment_currency are correct
    # process payment
    my $status = $c->param('payment_status');
    if ($status eq 'Completed') {
      _log_paypal_info($query, $c->session->{uemail}||"noemail\@gmail.com", $c->tx->remote_address, $c->req->headers->referrer);
      _send_email($c);
    }
  } elsif ($res->content eq 'INVALID') {
    # log for manual investigation
    _log_paypal_error($res, $c->session->{uemail}||"noemail\@gmail.com", $c->tx->remote_address, $c->req->headers->referrer);
  } else {
    # error
    _log_paypal_error($res, $c->session->{uemail}||"noemail\@gmail.com", $c->tx->remote_address, $c->req->headers->referrer);
  }
  print "content-type: text/plain\n\n";
};


################
sub _log_paypal_error {
  my ($res, $myemail, $ip, $referer) = @_;
  my $timestamp = localtime();

   open(my $FD, ">> /var/paypal/paypal_error.txt") or die "Can't find paypal_error.txt : $!";
   print $FD "[$timestamp] - INVALID: ".$res->message;
   close($FD);

  paypallog( 'err', $myemail, $ip, $referer, "[$timestamp] - INVALID: ".$res->message );
  print STDERR "_log_paypal_error exits on $ip $myemail $referer\n";
}


################
use SylSpace::Model::Utils qw( _burpapp _decryptdecode );

sub _log_paypal_info {
  my ($query, $myemail, $ip, $referer) = @_;
  _burpapp( undef, "paypalquery: $query\n" );

  ## we want to do minor rearranging.  we want to push 'payer_email' to the front and decrypt custom (following front);

  my $sessionemail=""; my $payeremail="";
  foreach my $pair ( split(/&/, $query) ) {
    my ($key, $value) = split("=", $pair);
    (($key eq 'custom') || ($key eq 'payer_email')) or next;

    $value =~ tr/+/ /;
    $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C",hex($1))/eg;

    ($key eq 'custom') and $sessionemail= _decryptdecode($value);
    ($key eq 'payer_email') and $payeremail= $value;
  }

  _burpapp( undef, "paypallink: $sessionemail\t$payeremail\n" );

  my $logmore="$sessionemail\t$payeremail\t$query\n";

  _burpapp( "/var/paypal/paypal_info.txt", $logmore );
  paypallog( 'ok', $myemail, $ip, $referer, $logmore );  ## this must work, too.

  print STDERR "_log_paypal_info exits on $ip $myemail $referer $logmore";
}


################
sub _send_email {
  my ($c) = @_;
  my $config = $c->app->plugin('Config');

  my $message = Email::Simple->create(
				      header => [
						 From    => $config->{paypal}{notify_email},
						 To      => $config->{paypal}{notify_email},
						 Subject => 'Paypal Transaction - Completed',
						],
				      body => "Payment has been verified, validated, and captured.",
				     );

  sendmail($message, { transport => _getTransport($c) });
}


################
sub _getTransport {
  my $c = shift;

  return $c->{_transport} ||= Email::Sender::Transport::SMTP::TLS->new(
								       %{ $c->app->plugin('Config')->{email}{transport} }
								      );
}

################

1;
