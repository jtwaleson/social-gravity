function Downloader() {
	
	var self = this;
	self.currentDownloads = 0;
	self.readyCallback = null;	
	self.successCallBacks = {};
	self.errorCallBacks = {};

	self.justGet = function(resid, success, error, options) {
		if (typeof options == 'undefined')
			options = {};
		if (resid.length > 2) {
			self.successCallBacks[resid] = success;
			self.errorCallBacks[resid] = error;
			var request = options;
			request['resid'] = resid;
			request['url'] = self.urlFromResid(resid);
			self.enterDownloadStreet(request);
		} else
			self.readyCallback();
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
	self.enterDownloadStreet = function(request) {
		self.currentDownloads++;
		self.localWorker(request);
	}
	self.localWorker = function(req) {
		if (req['resid'].substr(0,2) != 'l_' && !req['nolocal']) {
			var s = sessionStorage.getItem(req['resid']);
			if (s != null) {
				req['result'] = JSON.parse(s);
				req['origin'] = 'local';
			}
		}
		self.cacheWorker(req);
	}
	self.cacheWorker = function(req) {
		if (req['nocache'] || req['result'])
			self.twitterWorker(req);
		else 
			$.ajax({
				url: "/cache/"+req['resid'],
				dataType: "json",
				type: 'GET',
				error: function(xhr, textStatus, errorThrown){
					if (xhr.status == 404)
						self.twitterWorker(req);
					else
						alert('Server cache gave error code' + xhr.status);
				},
				success: function(r,a,xhr) {
					req['result'] = r;
					req['origin'] = 'cache';
					self.twitterWorker(req);
				}
			});
	}
	//this is not a real worker, because jsonp requests cannot be done in a Worker thread
	self.twitterWorker = function(req) {
		if (typeof req['result'] != 'undefined' || req['notwitter'])
			self.pipesWorker(req);
		else {
			$.ajax({
				type: 'POST',
				url: req['url'],
				dataType: "jsonp",
				success: function(r,a,xhr) {
					if (req['resid'].substr(0,2) == 'u_') {
						r = r[0]
						req['resid2'] = 'n_'+r['screen_name'];
					} else if (req['resid'].substr(0,2) == 'n_') {
						r = r[0];
						req['resid2'] = 'u_'+r['id'];
					}
					req['origin'] = 'twitter';
					req['result'] = r;
					self.pipesWorker(req);
					$.post('/cache/'+req['resid'], {data:JSON.stringify(r)});
				},
				timeout: (req['resid'].substr(0,2) == 'f_' ? 30000 : 6000),
				error: function(e) {
					self.pipesWorker(req);
				}
			});
		}
	}
	self.pipesWorker = function(req) {
		if (typeof req['result'] != 'undefined' || req['nopipes'])
			self.proxyWorker.postMessage(req);
		else {
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
						req['origin'] = 'yahoo';
						req['result'] = r;
						self.proxyWorker.postMessage(req);
						$.post('/cache/'+req['resid'], {data:JSON.stringify(r)});
					} else
						self.proxyWorker.postMessage(req);
				},
				timeout: (req['resid'].substr(0,2) == 'f_' ? 50000 : 6000),
				error: function(e) {
					self.proxyWorker.postMessage(req);
				}
			});
		}
	}
	self.proxyWorker = new Worker('/js/downloader_proxy.js');
	self.proxyWorker.onmessage = function(data) {
		var request = data['data'];
		if (typeof request['result'] == 'undefined') {
			if (request['resid'] in self.errorCallBacks)
				self.errorCallBacks[request['resid']]();
		} else {
			if (request['resid'] in self.successCallBacks)
				self.successCallBacks[request['resid']](request);
		}
		delete self.successCallBacks[request['resid']];
		delete self.errorCallBacks[request['resid']];
		self.currentDownloads--;
		if (self.currentDownloads == 0)
			self.readyCallback();

	}
}
function hithere(data) {
	console.log(data);
}
