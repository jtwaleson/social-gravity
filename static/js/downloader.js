function Downloader() {
	var self = this;

	self.byUserName = function(username, success) {
		self.resolve(
			'/cache/userbyname/'+username.toLowerCase(), 
			'http://api.twitter.com/1/users/lookup.json?screen_name='+username,
			function(data) {
				if(data[0]['protected'] == false || data[0]['protected'] == 'false') 
					self.findUser(data, success)
				else
					alert('This account is protected');
				},
			function() {
				alert('Sorry, could not resolve ' + username);
			}
		);
	}
	self.byUserId = function(id, success) {
		self.resolve(
			'/cache/user/'+id, 
			'http://api.twitter.com/1/users/lookup.json?user_id='+id,
			function(data) { self.findUser(data, success) },
			function() {
				alert('Sorry, could not resolve ' + id);
			}
		);
	}
	self.go = function() {
		k = 0;
		for (id in users) {
			if (users[id] == 0) {
				k++;
				var f = function() {
					var i = id;
					self.cache('/cache/user/'+i, function(data){$("#friend_"+i).css('background-color', 'red').text(data[0]['screen_name']); users[i] = 3;}, function(){console.log(i+' not found'); users[i] = 1;});
				}()
			}
			if (k >= 10)
				return;
		}
		for (id in users) {
			if (users[id] == 1) {

			}
		}
	}

	//INTERNALS
	self.resolve = function(cacheUrl, twitterUrl, success, error) {
		self.cache(cacheUrl, success, function(){ 
			self.resolveWithoutCache(twitterUrl, success, error);
		});
	}
	self.resolveWithoutCache = function(twitterUrl, success, error) {
		self.twitter(twitterUrl, success, function() {
			self.pipes(twitterUrl, success, error);
		});
	}

	self.cache = function(cacheUrl, success, error) {
		$.ajax({
			url: cacheUrl,
			datatype: "json",
			type: 'get',
			error: function(xhr, textstatus, errorthrown){
				if (xhr.status == 404)
					error();	
				else
					alert('server cache gave an unexpected error code' + xhr.status);
			},
			success: function(r,a,xhr) {
				success(r);
			},
		});
	}
	self.twitter = function(twitterUrl, success, error) {
                $.ajax({
                        url: twitterUrl,
                        type: 'POST',
                        dataType: "jsonp",
                        error: function(e) {
                               error(); 
                        },
                        success: function(r,a,xhr) {
                                success(r);
                        },
                        timeout: 10000,
                });
	}
	self.pipes = function(twitterUrl, success, error) {
                $.ajax({
                        type: 'POST',
                        data: { _id: '81263ca2954c525a92e8ebe02b9c5a82',
                                _render: 'json',
                                url: twitterUrl},
                        url: 'http://pipes.yahoo.com/pipes/pipe.run',
                        dataType: "jsonp",
                        jsonp: "_callback",
                        success: function(r,a,xhr) {
                                if (r['count'] > 0) {
                                        r = r['value']['items'];
					success(r)
                                } else
                                        error();
                        },
                        timeout: 10000,
                        error: error,
                });
	}
	self.findUser = function(data, success, error) {
		if (data.length == 1) {
			data = data[0];
			if ('friends' in data)
				success(data);
			else {
				if (data['protected'] == false || data['protected'] == 'false') 
					self.findFriends(data, success, function(){alert('User found, but could not retrieve friends');});
				else
					success(data);
			}
		} else if (data.length > 1)
			alert('Found more than one user...');
		else if (data.length == 0)
			alert('Found no users');
	}
	self.findFriends = function(profile, success, error) {
		self.resolveWithoutCache(
			'http://api.twitter.com/1/friends/ids.json?cursor=-1&user_id='+profile['id_str'],
			function(data) {
				profile['friends'] = data;
				$.post('/cache/user/'+profile['id'], {data: JSON.stringify(profile)});
				success(profile);
			},
			error
		)	
	}
}
