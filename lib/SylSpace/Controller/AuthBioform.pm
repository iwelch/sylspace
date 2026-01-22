#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.


package SylSpace::Controller::AuthBioform;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(readschema bioread userexists);
use SylSpace::Model::Controller qw(standard global_redirect  drawform);

################################################################

get '/auth/bioform' => sub {
  my $c = shift;
  # (my $course = standard( $c )) or return global_redirect($c);

  userexists($c->session->{uemail}) or die "internal error: you were never created";

  $c->stash( udrawform=> drawform( readschema('u'), bioread($c->session->{uemail}) ) );
};


1;

################################################################

__DATA__

@@ authbioform.html.ep

%title 'user bio';
%layout 'auth';

<style>
  /* Two-column layout for bio form on larger screens */
  @media (min-width: 992px) {
    .bio-form-grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 0 2em;
    }
    .bio-form-grid .form-group {
      margin-bottom: 15px;
    }
  }
  /* Single column on smaller screens */
  @media (max-width: 991px) {
    .bio-form-grid {
      display: block;
    }
  }
</style>

<main>

  <form class="form-horizontal" method="POST" action="/auth/biosave">

  <div class="form-group">
    <label class="col-sm-2 control-label" for="email">email*</label>
       <div class="col-sm-6">[public unchangeable]
          <input class="form-control foo" id="email" name="email" value="<%= $self->session->{uemail} %>" readonly />
       </div>
  </div>

  <div class="bio-form-grid">
  <%== $udrawform %>
  </div>

  <!-- div class="form-group" style="padding-top:2em">
    <label class="col-sm-2 control-label" for="directlogincode">[c] directlogincode</label>
    <div class="col-sm-6">[Super-Confidential, Not Changeable, Ever]<br />  <a href="auth/showdirectlogincode">click here to play with knives</a><br /> </div>
  </div -->

  <div class="form-group" style="clear:both; padding-top:1em;">
     <button class="btn btn-lg btn-default" type="submit" value="submit">Submit These Settings</button>
  </div>

  <script>
      var clientDate = new Date(); //Get date on current client machine
      var clientDateTimeOffset = (clientDate.getTimezoneOffset() * -1); //account for the offset
      var convertToHours = clientDateTimeOffset/60; //Convert it to hours
      $("#tzi").val(convertToHours); //Update the input control
  </script>

  </form>

  <p> <b>*</b> means required (red if not yet provided).</p>

  <p> <b>tzi</b> is your timezone.  Typically, this will be filled in correctly by your browser.  It helps SylSpace render time expiration notices not in UTC, but in your local timezone.  If you want to tinker with it:  0 = UTC.  -7 = PST(Summer), -8 = PST(Winter).  +8 = China.</p>

<hr />

<h3><i class="fa fa-key"></i> Passkey Authentication</h3>

<p>Register a passkey to sign in with Face ID, Touch ID, Windows Hello, or a security key on future visits — no password needed.</p>

<div id="passkey-status" class="alert" style="display:none;"></div>

<button id="passkey-register-btn" class="btn btn-success btn-lg">
  <i class="fa fa-plus"></i> Register Passkey for This Device
</button>

<p style="font-size:small; margin-top:1em;">You can register multiple passkeys (e.g., one for your phone, one for your laptop). Each device needs its own passkey.</p>

<script>
function base64urlToBuffer(base64url) {
  const base64 = base64url.replace(/-/g, '+').replace(/_/g, '/');
  const pad = base64.length % 4;
  const padded = pad ? base64 + '='.repeat(4 - pad) : base64;
  const binary = atob(padded);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes.buffer;
}

function bufferToBase64url(buffer) {
  const bytes = new Uint8Array(buffer);
  let binary = '';
  for (let i = 0; i < bytes.length; i++) {
    binary += String.fromCharCode(bytes[i]);
  }
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

function showPasskeyStatus(msg, isError) {
  const el = document.getElementById('passkey-status');
  el.textContent = msg;
  el.className = 'alert ' + (isError ? 'alert-danger' : 'alert-success');
  el.style.display = 'block';
}

if (!window.PublicKeyCredential) {
  showPasskeyStatus('Passkeys are not supported in this browser.', true);
  document.getElementById('passkey-register-btn').disabled = true;
}

document.getElementById('passkey-register-btn').addEventListener('click', async function() {
  try {
    const optionsRes = await fetch('/auth/passkey/register/begin', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: ''
    });
    const options = await optionsRes.json();
    
    if (options.error) {
      showPasskeyStatus(options.error, true);
      return;
    }
    
    options.publicKey.challenge = base64urlToBuffer(options.publicKey.challenge);
    options.publicKey.user.id = base64urlToBuffer(options.publicKey.user.id);
    if (options.publicKey.excludeCredentials) {
      options.publicKey.excludeCredentials = options.publicKey.excludeCredentials.map(c => ({
        ...c,
        id: base64urlToBuffer(c.id)
      }));
    }
    
    const credential = await navigator.credentials.create(options);
    
    const finishRes = await fetch('/auth/passkey/register/finish', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        id: credential.id,
        rawId: bufferToBase64url(credential.rawId),
        type: credential.type,
        response: {
          clientDataJSON: bufferToBase64url(credential.response.clientDataJSON),
          attestationObject: bufferToBase64url(credential.response.attestationObject)
        }
      })
    });
    const result = await finishRes.json();
    
    if (result.success) {
      showPasskeyStatus('Passkey registered! You can now use it to sign in.', false);
    } else {
      showPasskeyStatus(result.error || 'Registration failed', true);
    }
  } catch (err) {
    console.error(err);
    if (err.name === 'NotAllowedError') {
      showPasskeyStatus('Registration was cancelled.', true);
    } else {
      showPasskeyStatus('Error: ' + err.message, true);
    }
  }
});
</script>

</main>


