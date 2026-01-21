#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::InstructorEdit;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(sudo);
use SylSpace::Model::Files qw(filereadi);
use SylSpace::Model::Controller qw(global_redirect  standard);

################################################################

get 'instructor/edit' => sub {
  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);

  sudo( $course, $c->session->{uemail} );

  my $filename= $c->req->query_params->param('f');
  my $filecontent= filereadi( $course, $filename );
  my $filelength= length($filecontent);

  $filecontent =~ s/\r\n/\r/g;
  $filecontent =~ s/\r/\n/g;

  use Digest::MD5 qw(md5_hex);
  my $is_equiz = ($filename =~ /\.equiz$/i) ? 1 : 0;
  $c->stash( filelength => $filelength, filename => $filename, filecontent => $filecontent, 
             fingerprint => md5_hex($filecontent), is_equiz => $is_equiz );
};

1;

################################################################

__DATA__

@@ instructoredit.html.ep

%title 'edit a file';
%layout 'instructor';

<style> 
  textarea.textarea {  font-family: monospace;  display:block;  height:80vh;  width:100%;  line-height:16px;  padding:5px;  margin:0px auto;  }
  #syntaxError { display: none; margin: 10px 0; padding: 15px; background: #f8d7da; border: 1px solid #f5c6cb; border-radius: 5px; color: #721c24; }
  #syntaxError.show { display: block; }
</style>


<main>

  <% if ($is_equiz) { %>
  <div style="margin-bottom: 15px;">
    <button id="saveViewBtn" class="btn btn-lg btn-primary btn-block" style="font-size:large;">
      <i class="fa fa-save"></i> Save and View in New Window
    </button>
  </div>
  <div id="syntaxError"></div>
  <% } %>

  <form method="POST" action="editsave" id="editForm">

  <input type="hidden" name="fname" value="<%= $filename %>" />
  <input type="hidden" name="fingerprint" value="<%= $fingerprint %>" />
  <input type="hidden" name="filelength" value="<%= $filelength %>" />

  <textarea name="content" id="textarea" spellcheck="false" class="textarea"><%= $filecontent %></textarea>

  <script type="text/javascript" src="/js/confirm.js"></script>

  <div class="row top-buffer text-center">
  <div class="col-md-12">
     <button class="btn btn-lg btn-default btn-block btn-danger" name="submitbutton"  type="submit" value="combine" style="font-size:x-large"  onclick="show_alert();">Save Changes</button>
  <p>This will overwrite the original!</p>
  </div> <!--col-md-12-->
  </div> <!--row-->

  </form>

  <% if ($is_equiz) { %>
  <script>
  document.getElementById('saveViewBtn').addEventListener('click', function(e) {
    var btn = this;
    var errorDiv = document.getElementById('syntaxError');
    var textarea = document.getElementById('textarea');
    var content = textarea.value;
    var fname = '<%= $filename %>';
    
    // Open the window IMMEDIATELY (synchronously) to avoid popup blocker
    var viewWindow = window.open('about:blank', '_blank');
    if (!viewWindow) {
      alert('Popup blocked! Please allow popups for this site.');
      return;
    }
    viewWindow.document.write('<html><head><title>Loading...</title></head><body><h2>Checking syntax and saving...</h2></body></html>');
    
    btn.disabled = true;
    btn.innerHTML = '<i class="fa fa-spinner fa-spin"></i> Checking syntax...';
    errorDiv.className = '';
    errorDiv.style.display = 'none';
    
    // Step 1: Syntax check
    fetch('/instructor/equizsyntax', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: 'content=' + encodeURIComponent(content)
    })
    .then(function(response) { return response.json(); })
    .then(function(data) {
      if (!data.ok) {
        // Syntax error - close the window and show error
        viewWindow.close();
        errorDiv.innerHTML = '<strong>Syntax Error:</strong> ' + data.error;
        if (data.line) {
          errorDiv.innerHTML += '<br><em>Near line ' + data.line + '</em>';
          // Scroll to that line
          var lines = content.split('\n');
          var pos = 0;
          for (var i = 0; i < data.line - 1 && i < lines.length; i++) {
            pos += lines[i].length + 1;
          }
          textarea.focus();
          textarea.setSelectionRange(pos, pos + (lines[data.line-1] || '').length);
        }
        errorDiv.className = 'show';
        errorDiv.style.display = 'block';
        btn.disabled = false;
        btn.innerHTML = '<i class="fa fa-save"></i> Save and View in New Window';
        return Promise.reject('syntax error');
      }
      
      // Step 2: Save
      btn.innerHTML = '<i class="fa fa-spinner fa-spin"></i> Saving...';
      viewWindow.document.body.innerHTML = '<h2>Saving...</h2>';
      return fetch('/instructor/equizsaveajax', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: 'fname=' + encodeURIComponent(fname) + '&content=' + encodeURIComponent(content)
      });
    })
    .then(function(response) { 
      return response.json(); 
    })
    .then(function(data) {
      if (!data.ok) {
        viewWindow.close();
        errorDiv.innerHTML = '<strong>Save Error:</strong> ' + data.error;
        errorDiv.className = 'show';
        errorDiv.style.display = 'block';
        btn.disabled = false;
        btn.innerHTML = '<i class="fa fa-save"></i> Save and View in New Window';
        return;
      }
      
      // Step 3: Navigate the window to the view
      btn.innerHTML = '<i class="fa fa-check"></i> Saved!';
      viewWindow.location.href = '/instructor/equizview?f=' + encodeURIComponent(fname);
      
      // Reset button
      setTimeout(function() {
        btn.disabled = false;
        btn.innerHTML = '<i class="fa fa-save"></i> Save and View in New Window';
      }, 1000);
    })
    .catch(function(err) {
      if (err !== 'syntax error') {
        viewWindow.close();
        errorDiv.innerHTML = '<strong>Error:</strong> ' + err;
        errorDiv.className = 'show';
        errorDiv.style.display = 'block';
      }
      btn.disabled = false;
      btn.innerHTML = '<i class="fa fa-save"></i> Save and View in New Window';
    });
  });
  </script>
  <% } %>

</main>

