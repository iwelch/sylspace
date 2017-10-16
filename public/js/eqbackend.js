$(document).ready(function() {
    $(window).keydown(function(event){
	if(event.keyCode == 13) {
	    if ( $(event.target).is('input:submit') ) {
		event.preventDefault();
		return false;
	    }
	}
    });

    $("select.searchable").each(function() {
	$(this).chosen({allow_single_deselect:true});
	console.log('foo');
    });
});

$(window).bind("pageshow", function() {
    var form = $('form');
    form[0].reset();
});


$('textarea').each(function () {
    this.setAttribute('style', 'height:' + (this.scrollHeight) + 'px;overflow-y:hidden;');
}).on('input', function () {
    this.style.height = 'auto';
    this.style.height = (this.scrollHeight) + 'px';
});
