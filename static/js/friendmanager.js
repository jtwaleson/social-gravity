function FriendManager(viewPort, simulation, downloader) {
	var self = this;

	self.viewPort = viewPort;
	self.simulation = simulation;
	self.persons = {};
	self.downloader = downloader;
	self.amount = 0;
	self.amountParsed = 0;
	self.amountProtected = 0;
	self.simulation.friendmanager = self;

	self.add = function(id) {
		self.persons[id] = new Friend(id);
		self.amount++;
		$(".tweepcount").text(self.amount);
	}
	self.getProfiles = function() {
		var ids = [];
		for (var i in self.persons)
			if (!self.persons[i].hasinfo)
				ids.push(i);
		var resid = 'l_'+ids.join(',');
		self.downloader.justGet(resid, self.parseProfiles, self.error);
	}
	self.error = function() {
	}
	self.parseProfiles = function(data) {
		for (var i in data['result']) {
			var u = data['result'][i];
			self.persons[u.id].setInfo(u);
			self.amountParsed++;
		}
		$(".tweepProfilesParsed").text(self.amountParsed);
		$(".privateaccounts").text(self.amountProtected);
	}
	self.startDownloading = function() {
		self.phase++;
		var ids = [];
		$(".loading_small").hide();
		for (var i in self.persons) {
			if (!self.persons[i].prot && !self.persons[i].friendsRetrieved)
				ids.push(i);
		}
		if (ids.length == 0 || self.phase >= 4) {
			$("#configurebtn").removeClass('disabled');
			if (ids.length > 0)
				$("#pleasecomeback").show();
			$("#progress").hide();
			return;
		}
		$("#downloads"+self.phase+" .loading_small").show();
		
		for (i in ids) {
			
		}
		self.downloader.readyCallback = self.startDownloading;
		var max = ids.length;
		if (self.phase == 2)
			max = 450;
		if (self.phase == 3)
			max = 150;
		if (self.phase == 1) {
			var subids = []
			for (i in ids) {
				subids.push(ids[i]);
				if ((i % 50 == 0 || i == ids.length -1) && subids.length > 0) {
					self.downloader.justGet('q_'+subids.join(','), self.setPersonMultipleFriends, self.setPersonFriendsError, {nolocal: 1, notwitter:1,nopipes:1,noproxy:1});
					for (j in subids)
						self.incField('.requested', 1);
					subids = [];
				}
			}
		} else {
			for (var i in ids) {
				if (max-- > 0) {
					var id = ids[i];
					self.downloader.justGet('f_'+id, self.setPersonFriends, self.setPersonFriendsError, 
							{nolocal: (self.phase != 0), 
							nocache: (self.phase != 1), 
							notwitter: (self.phase != 3), 
							nopipes: (self.phase != 2), 
							noproxy: (self.phase != 4)});
					self.incField(".requested");
				}
			}
		}
	}
	self.setPersonFriendsError = function() {
		self.incField('.error');
	}
	self.incField = function(f, p, n) {
		if (typeof p == 'undefined')
			p = self.phase;
		var a = $("#downloads"+p+" "+f);
		if (typeof n == 'undefined') {
			var n = 0;
			if (a.text().length > 0)
				n = parseInt(a.text());
			n++;
		}
		a.text(n);
	}
	self.setPersonMultipleFriends = function(data) {
		var n = data['requestcount'];
		for (i in data['result']) {
			n--;
			self.incField('.retrieved');
			self.persons[i.substr(2)].setFriends({resid: i, result: data['result'][i]});
		}
		while (n > 0) {
			self.incField('.error',1);
			n--;
		}
	}
	self.setPersonFriends = function(data) {
		self.incField(".retrieved");
		self.persons[data['resid'].substr(2)].setFriends(data);
	}
	self.getInnerConnections = function () {
		self.simulation.setFriends(self.getFriendsExport());
		self.simulation.setConnections(self.getConnections());
		self.simulation.start();
	}
	self.clear = function () {
		self.simulation.stop();
		for (var i in self.persons)
			self.persons[i].div.remove();
		self.persons = {};
		self.amount = 0;
		self.amountParsed = 0;
		self.amountProtected = 0;
		self.drawStrongConnections = false;
		for (var i = 0; i <= 4; i++)
			for (var j in {'.error': 1, '.retrieved': 1, '.requested': 1, '.total': 1})
				self.incField(j, i, '0')
		self.viewPort.reset();
	}
	self.getFriendsExport = function() {
		var r = {};
		for (var i in self.persons)
			r[i] = {x: self.persons[i].x, y: self.persons[i].y};
		return r;
	}
	self.toggleDrawStrongConnections = function() {
		self.drawStrongConnections = !self.drawStrongConnections;
		self.drawAllLines();
	}
	self.doDrawStrongConnections = function() {
		var ctx = $('#c')[0].getContext("2d");
		ctx.beginPath();                    
		for (var i in self.persons) {
			self.persons[i].drawStrongLines(ctx);
		}
		ctx.strokeStyle = '#888';
		ctx.stroke();
	}
	self.drawConnections = function() {
		var ctx = $('#c')[0].getContext("2d");
		ctx.beginPath();                    
		for (var i in self.persons) 
			if (self.persons[i].drawlines) {
				for (var j in self.persons[i].friends)
					self.persons[i].drawLine(ctx, j);
				for (var j in self.persons)
					if (i in self.persons[j].friends)
						self.persons[j].drawLine(ctx, i);
			}
		ctx.strokeStyle = '#ccc';
		ctx.stroke();
	}
	self.getConnections = function () {
		var conn = {};
		if (self.simulation.settings['assume_mutual_when_protected'])
			for (var i in self.persons)
				for (var j in self.persons[i].friends)
					if (j in self.persons && self.persons[j].prot)
						self.persons[j].friends[i] = 1;
		var a,b;
		var m = self.simulation.settings['mutualscore'];
		var f = self.simulation.settings['friendscore'];
		var c = self.simulation.settings['commonscore'];
		var t = self.simulation.settings['friendthreshold'];

		for (var i in self.persons) {
			a = self.persons[i];
			for (var j in a.friends)
				if (j in self.persons) {
					b = self.persons[j];
					if (typeof conn[i] == 'undefined')
						conn[i] = {};
					if (typeof conn[i][j] == 'undefined') {
						var r = self.getStrength(a,b,m,f,c);
						if (r > t) 
							conn[i][j] = r;
					}
				}
		}
		for (var i in conn) {
			self.persons[i].strongconnections = conn[i];
			self.persons[i].calcStrongestConnections();
		}
		var max_total = 0;
		for (var i in self.persons) {
			var total = 0;
			if (!(typeof conn[i] == 'undefined'))
				for (var j in conn[i])
					total += conn[i][j];
			self.persons[i].total = Math.log(Math.max(total, 1));
			if (self.persons[i].total > max_total)
				max_total = self.persons[i].total;
		}
		for (var i in self.persons)
			self.persons[i].div.fadeTo('slow', self.simulation.settings['minvisibility'] + Math.max(0, (1-self.simulation.settings['minvisibility'])*(self.persons[i].total/max_total)));
		return conn;
	}
	self.updateAll = function() {
		self.viewPort.resetCanvas();
		for (var i in self.persons)
			self.persons[i].update();
		self.drawAllLines();
	}
	self.getStrength = function (a,b,m,f,c) {
		var score = 0;
		// simple scoring for if the users follow eachother
		if (i in self.persons[j].friends) {
			if (j in self.persons[i].friends)
				score = m; 
			else
				score = self.simulation.settings['friendscore'];
		}
//		if (j in self.persons[i].friends)
//			score += self.simulation.settings['friendscore'];
//		if (i in self.persons[j]score == self.simulation.settings['friendscore']*2)
//			score = 2;
			
		// mutual friends scores
		for (var k in self.persons[i].friends)
			if (k in self.persons[j].friends)
				score += self.simulation.settings['commonscore'];
		return score;
	}
	self.recalcPersonColors = function() {
		$(".friend.highlight").removeClass('highlight');
		$(".friend.highlight2").removeClass('highlight2');
		$(".friend.clicked").removeClass('clicked');
		
		for (var id in self.persons) {
			if (self.persons[id].drawlines) {
				self.persons[id].div.addClass('clicked');
				for (var fid in self.persons[id].friends) {
					if (fid in friendManager.persons) {
						self.persons[id].drawLine(fid);
						self.persons[fid].div.addClass('highlight');
					}
				}
				for (var i in self.persons) {
					if (id in self.persons[i].friends) {
						self.persons[i].drawLine(id);
						self.persons[i].div.addClass('highlight2');
					}
				}
			}
		}

	}
	self.drawAllLines = function() {
		self.viewPort.resetCanvas();
		self.drawConnections();
		if (self.drawStrongConnections)
			self.doDrawStrongConnections();
		var drawing = $("#playfield .clicked").size();
		if (drawing > 0) {
			$(".newnetwork").show();
		} else {
			$(".newnetwork").hide();
		}
	}
}
