function Downloader() {
	
	var self = this;
	
	self.enterDownloadStreet = function(request) {
		self.cache(request);
	}
	self.cache = function(req) {
		req['url'] = self.urlFromResid(req['resid']);
		$.ajax({
			url: "/cache/"+req['resid'],
			dataType: "json",
			type: 'GET',
			error: function(xhr, textStatus, errorThrown){
				if (xhr.status == 404)
					self.twitter(req);
				else
					alert('Server cache gave error code' + xhr.status);
			},
			success: function(r,a,xhr) {
				success(r);
			}
		});
	}
	self.twitter = function(req, success, error) {
		$.ajax({
			type: 'POST',
			url: req['url'],
			dataType: "jsonp",
			success: function(r,a,xhr) {
				success(r);
				$.post('/cache/'+req['resid'], {data:JSON.stringify(r)});
			},
			timeout: 10000,
			error: function(e) {
				self.pipes(req, success, error);
			}
		});
	}
	
	self.pipesWorker = function(req, success, error) {
		$.ajax({
			type: 'POST',
			data: {	_id: '81263ca2954c525a92e8ebe02b9c5a82',
				_render: 'json',
				url: req['url']},
			url: 'http://pipes.yahoo.com/pipes/pipe.run',
			dataType: "jsonp",
			jsonp: "_callback",
			success: function(r,a,xhr) {
				if (r['count'] > 0) {
					r = r['value']['items'][0];
					if (r['json'])
						r = r['json'];
					success(r)
					$.post('/cache/'+req['resid'], {data:JSON.stringify(r)});
				} else
					error();
			},
			timeout: (req['resid'].substr(0,2) == 'f_' ? 50000 : 6000),
			error: error
		});
	}
	
	self.urlFromResid = function(resid) {
		var a = resid.substr(0,2);
		var b = resid.substr(2);
		if (a == 'u_') {
			return 'https://api.twitter.com/1/users/lookup.json?user_id='+b;
		} else if (a == 'f_') {
			return 'https://api.twitter.com/1/friends/ids.json?cursor=-1&user_id='+b;
		} else if (a == 'g_') {
			return 'https://api.twitter.com/1/followers/ids.json?cursor=-1&user_id='+b;
		} else if (a == 'n_') {
			return 'https://api.twitter.com/1/users/lookup.json?screen_name='+b;
		} else if (a == 'l_') {
			return 'https://api.twitter.com/1/users/lookup.json?user_id='+b;
		}
	}
}
