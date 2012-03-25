importScripts('jquery.hive.pollen.js');

onmessage = function(data) {
	var plaindata = data['data'];
	$.ajax.post({
		url: '/cache/store',
		data: plaindata,
		type: 'POST',
		dataType: 'json'
	});
}
