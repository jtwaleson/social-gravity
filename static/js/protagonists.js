function Protagonists(downloader) {
	var self = this;
	self.downloader = downloader;
	self.list = [];
	self.add = function(name) {
		if (name.length > 0) {
			self.list.push({name: name, followers: -1, friends: -1, includeself: true, includefollowers: false, includefriends: true});
			self.generate();
			downloader.byUserName(name, function(data){var n = name; self.setInfo(n, data);}, function(){alert('Could not find user')});
		}
	}
	self.error = function() {
		alert('Could not find the user you selected');
	}
	self.change = function(i, name) {
		self.list[i][name] = !(self.list[i][name]);
		self.generate();
	}
	self.rm = function(i) {
		self.list.splice(i,1);
		self.generate();
	}
	self.generate = function() {
		$("#protagonists tbody .real").remove();
		for (var i in self.list)
			self.getTr(self.list[i], i);

		var total = 0;
		for (var k in self.getActualFriendsAndFollowers())
			total++;
		if (total > 2)
			$("#downloadbtn").removeClass('disabled');
		else
			$("#downloadbtn").addClass('disabled');
		$(".tweepcount").text(total);
		
		if (self.list.length > 1) {
			$("#thresholdslider").slider('option', 'max', self.list.length);
			$("#thresholdslider").show();
		} else {
			if ($("#thresholdslider").is(':visible')) {
				$("#thresholdslider").hide();
				$("#thresholdslider").slider('option', 'value', 1);
			}
		}
	}
	self.getActualFriendsAndFollowers = function() {
		var totality = {};
		for (var i in self.list)
			for (var j in self.getActualFriendsAndFollowersChild(i))
				totality[j] = 1 + (j in totality ? totality[j] : 0);
		var threshold = $("#thresholdslider").slider('value');
		for (var k in totality)					
			if (totality[k] < threshold)
				delete totality[k];
		for (var i in self.list) {
			var lid = self.list[i]['id'];
			if (self.list[i]['includeself'])
				totality[lid] = 1 + (i in totality ? totality[lid] : 0);
			else
				delete totality[lid];
		}

		return totality;
	}
	self.getActualFriendsAndFollowersChild = function(i) {
		var a = {};
		if (self.list[i]['includefollowers'] && typeof(self.list[i]['followers']) != 'undefined')
			for (var j in self.list[i]['followers'])
				a[self.list[i]['followers'][j]] = 1;
		if (self.list[i]['includefriends'] && typeof(self.list[i]['friends']) != 'undefined')
			for (var j in self.list[i]['friends'])
				a[self.list[i]['friends'][j]] = 1;
		return a;
	}
	self.clear = function() {
		while (self.list.length > 0)
			self.rm(0);
	}
	self.getTr = function(p, i) {
		var a = $("#protagonists .dummyrow").clone();
		a.removeClass('dummyrow');
		a.appendTo("#protagonists tbody");
		a.addClass('real');
		a.attr('rel', i)
		a.find('.name').text(p['name']);
		a.find('.followers input[type=text]').val(typeof(p['followers']) == 'undefined' ? '?' : p['followers'].length);
		a.find('.friends input[type=text]').val(typeof(p['friends']) == 'undefined' ? '?' : p['friends'].length);
		for (var k in {friends: 1, followers: 1, self: 1}) {
			if (p['include'+k]) {
				a.find('.'+k+' label').addClass('active');
				a.find('.'+k+' input[type=checkbox]').attr('checked', 'checked');
			} else {
				a.find('.'+k+' input[type=checkbox]').removeAttr('checked');
			}
		}
		a.show();
	}
	self.setInfo = function(name, data) {
		var user = data['result'];
		for (var i in self.list) {
			if (self.list[i]['name'].name) {
				if (user['protected'] == true || user['protected'] == "true") {
					alert('Sorry, this account is protected');
					self.rm(i);
					return;
				}
				self.list[i]['name'] = user['screen_name'];
				self.list[i]['id'] = user['id'];
				break;
			}
		}
		self.generate();
	}
	self.setFollowers = function(data) {
		var id = data['resid'].substr(2);
		for (var i in self.list) {
			if (self.list[i]['id'] == id) {
				self.list[i]['followers'] = data['result']['ids'];
				break;
			}
		}					
		self.generate();
	}
	self.setFriends = function(data) {
		var id = data['resid'].substr(2);
		for (var i in self.list) {
			if (self.list[i]['id'] == id) {
				self.list[i]['friends'] = data['result']['ids'];
				break;
			}
		}
		self.generate();
	}
}
