importScripts('jquery.hive.pollen.js');

onmessage = function(data) {
	var req = data['data'];
	if (true || typeof req['result'] != 'undefined' || req['noproxy'])
		postMessage(req);
	else {	
		$.ajax.post({
			url: "http://waleson.com/twit3/backend/proxy.php",
			data: req,
			dataType: "json",
			success: function(r,a,xhr) {
				if (r['error'] == false) {
					req['origin'] = 'proxy';
					req['result'] = r['data'];
					req['original'] = r;
				}
				postMessage(req);
			}
		});
	}
}
