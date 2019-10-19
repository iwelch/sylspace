
function show_alert(e) {
    e.preventDefault();
    if(confirm("Do you really want to replace '<%= $filename %>'?"))
        document.forms[0].submit();
    else
        return false;
}

function show_msgdeletealert() {
    if(confirm("Do you really want to delete this message?"))
	document.forms[0].submit();
    else
	document.forms[0].cancel();
    return false;
}
