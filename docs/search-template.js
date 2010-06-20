function search(frm) {
    var matches, list, instance, up;
    var search_value = frm.value;
    
    matches = index[search_value];
    
    list = '';
    list = search_value + ':'

    if ( matches == undefined ) {
        list += '<font color=#FF0000>not found!</font>';
    } else if ( matches.length == undefined ) {
    } else if ( matches.length == 1 ) {
	document.location = matches[0].url;
	return false;
    } else {
	list += '<ul>';
	for (i=0; i < matches.length; ++i) {
	    instance = index[search_value][i];
	    list += '<li>';
	    list += "<a href=" + instance.url + ">" + chapter[instance.chapter] + '(' + instance.chapter + ') : ' + search_value + "</a>";
	    list += '</li>';
	}
	list += '</ul>';
    }
    searchresults.innerHTML = list; 
    return false;    
}
