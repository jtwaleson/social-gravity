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
		self.downloader.users[id] = 0;
		self.persons[id] = new Friend(id);
		self.amount++;
		$(".tweepcount").text(self.amount);
	}
	self.error = function() {
	}
	self.getInnerConnections = function () {
		self.simulation.setFriends(self.getFriendsExport());
		self.simulation.setConnections(self.getConnections());
		self.simulation.start();
	}
	self.clear = function () {
		self.downloader.users = {};
		self.downloader.resetUsage();
		self.simulation.stop();
		for (var i in self.persons)
			self.persons[i].div.remove();
		self.persons = {};
		self.amount = 0;
		self.amountParsed = 0;
		self.amountProtected = 0;
		self.drawStrongConnections = false;
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
