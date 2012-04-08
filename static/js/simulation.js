function Simulation() {
	var self = this;
	self.settings = {
		dst: 300, 
		attraction: 0.5, 
		repulsion: 1.0, 
		movetocenter: 1.5, 
		minvisibility: 0.3, 
		friendscore: 2,
		mutualscore: 4, 
		commonscore: 0.4, 
		friendthreshold: 6,
		closefriendthreshold: 0,
		assume_mutual_when_protected: true
	}
	self.d = new Date();
	self.lastUpdate = self.d.getTime();
	self.running = false;
	self.worker = new Worker('js/analysis_worker.js');
	self.worker.postMessage({settings: self.settings});
	self.worker.onmessage = function(data) {
		if (typeof data['data'] == 'object') {
			if ('friends' in data['data']) {
				var f = data['data']['friends'];
				var count = 0;
				for (var i in f) {
					p = self.friendmanager.persons[i];
					
					if (!p.locked) {
						p.x = f[i]['x'];
						p.y = f[i]['y'];
					}
					p.n = f[i]['n'];
					self.friendmanager.persons[i].update();
					count++;
				}
				for (var i in f) {
					self.friendmanager.persons[i].updateZIndex(count);
				}
				friendManager.drawAllLines();
				self.lastUpdate = (new Date()).getTime();
			}
			if (self.running) {
				if ((new Date()).getTime() - self.lastUpdate < 500)
					self.worker.postMessage({iter: true});
				else
					self.worker.postMessage({run: true});
			}
		} else {
			console.log(data['data']);
		}
	}
	self.lock = function(p) {
		self.worker.postMessage({lock: p.id, x: p.x, y: p.y});
	}
	self.unlock = function(p) {
		self.worker.postMessage({unlock: p.id});
	}
	self.start = function () {
		$("#running .stop").show();
		$("#running .start").hide();
		self.running = true;
		self.worker.postMessage({iter: true});
	}
	self.stop = function () {
		self.running = false;
		$("#running .start").show();
		$("#running .stop").hide();
		self.worker.postMessage({stop: true});
	}
	self.toggle = function() {
		if (self.running)
			self.stop();
		else
			self.start();
	}
	self.setFriends = function(data) {
		self.worker.postMessage({friends: data});
	}	
	self.setConnections = function(data) {
		self.worker.postMessage({connections: data});
	}
	self.filter = function(amount) {
		self.settings['closefriendthreshold'] += amount;
		if (self.settings['closefriendthreshold'] < 0)
			self.settings['closefriendthreshold'] = 0;
		$.jGrowl("Filter: "+self.settings['closefriendthreshold']);
		self.friendmanager.updateAll();
	}
}
