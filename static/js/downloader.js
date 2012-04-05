function Downloader() {
	var self = this;
	self.twitterTried = 0;
	self.pipesTried = 0;

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
		var stage10 = self.findUsersInState(10);
		for (i in stage10) {
			var id = stage10[i];
			$("#friend_"+id).css('background-color', 'green')
			if (!('friends' in userProfiles[id] && 'ids' in userProfiles[id]['friends'])) {
				$("#friend_"+id).css('background-color', 'black').text(userProfiles[id]['screen_name']);
			} else {
				$("#friend_"+id).css('background-color', 'green').text(userProfiles[id]['screen_name'] + ' COUNT::' + userProfiles[id]['friends']['ids'].length);
			}
				
			users[id] = 11;
		}

		var stage0 = self.findUsersInState(0, 10);
		if (stage0.length > 0) {
			for (i in stage0) {
				var f = function() {
					var id = stage0[i];
					self.cache('/cache/user/'+id, 
						function(data){
							userProfiles[id] = data[0];
							users[id] = 10;
						}, 
						function(){
							users[id] = 1;
						});
				}()
			}
			return;
		}

		if (self.twitterFailed) {
			self.pushAllFromState(1, 2);
			self.pushAllFromState(5, 6);
		}
		if (self.pipesFailed) {
			self.pushAllFromState(2, 4);
			self.pushAllFromState(6, 4);
		}
		var stage3 = self.findUsersInState(3);
		// no return after this one 
		for (i in stage3) {
			var prot = userProfiles[stage3[i]]['protected'];
			console.log(prot);
			if (prot === false || prot == 'false') {
				console.log('extrafalse');
				users[stage3[i]] = 5;
			} else
				users[stage3[i]] = 7;
		}
		var stage7 = self.findUsersInState(7, 10);
		if (stage7.length > 0) {
			for (i in stage7) {
				var f = function() {
					var id = stage7[i];
					$.post( '/cache/user/'+id, 
						{data: JSON.stringify(userProfiles[id])},
						function(){users[id] = 10;}
					);
				}()
			}
			return;
		}
		var stage5 = self.findUsersInState(5, 10);
		if (stage5.length > 0) {
			for (i in stage5) {
				var f = function() {
					var id = stage5[i];
					self.twitter(
						'http://api.twitter.com/1/friends/ids.json?cursor=-1&user_id='+id,
						function(data) {
							userProfiles[id]['friends'] = data;
							users[id] = 7;
						},
						function() {
							self.twitterFailed = true;
						}
					);
				}();
			}
			return;
		}

		var stage6 = self.findUsersInState(6, 10);
		if (stage6.length > 0) {
			for (i in stage6) {
				var f = function() {
					var id = stage6[i];
					self.pipes(
						'http://api.twitter.com/1/friends/ids.json?cursor=-1&user_id='+id,
						function(data) {
							userProfiles[id]['friends'] = data[0];
							users[id] = 7;
						},
						function() {
							self.pipesFailed = true;
						}
					);
				}();
			}
			return;
		}



		var stage1 = self.findUsersInState(1, 100);
		if (stage1.length > 0) {
			self.twitter(
				'http://api.twitter.com/1/users/lookup.json?user_id='+stage1.join(),
				function(data) {
					for (i in data) {
						userProfiles[data[i]['id']] = data[i];
						users[data[i]['id']] = 3;
					}
				},
				function() {
					self.twitterFailed = true;
				});
			return;
		}
		var stage2 = self.findUsersInState(2, 100);
		if (stage2.length > 0) {
			self.pipes(
				'http://api.twitter.com/1/users/lookup.json?user_id='+stage2.join(),
				function(data) {
					if (data.length == 1 && 'json' in data[0] && !('default_profile' in data[0]))
						data = data[0]['json'];
					for (i in data) {
						userProfiles[data[i]['id']] = data[i];
						users[data[i]['id']] = 3;
					}
				},
				function() {
					self.pipesFailed = true;
				});
			return;
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
                        timeout: 5000,
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
                        timeout: 5000,
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
	self.findUsersInState = function(state, maxnum) {
		var r = [];
		for (i in users)
			if (r.length != maxnum && users[i] == state)
				r.push(i);
		return r;
	}
	self.pushAllFromState = function(state, newstate) {
		for (i in users)
			if (users[i] == state)
				users[i] = newstate;
	}
}
