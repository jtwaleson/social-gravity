function ViewPort() {
	var self = this;
	self.x = 0;
	self.y = 0;
	self.zoom = 1;
	self.getWidth = function () {
		return $(window).width();
	};
	self.getHeight = function () {
		return $(window).height();
	};
	self.getOriginal = function (c) {
		return {x: c['x'] * self.zoom + self.x , y: c['y']*self.zoom + self.y};
	};
	self.getInflated = function (c) {					
		return {x: ((c['x']) - self.x)/self.zoom , y: ((c['y']) - self.y)/self.zoom};
	};
	self.reset = function () {
		self.x = 0;
		self.y = 0;
		self.zoom = 1;
		friendManager.updateAll();
	}
	self.move = function(num, amount) {
		if (typeof amount == 'undefined')
			amount = 0.1;
		var left = 0;
		var top = 0;
		if (num == 0) {
			left = -amount;
		} else if (num == 1) {
			top = -amount;
		} else if (num == 2) {
			left = amount;
		} else if (num == 3) {
			top = amount;
		}
		self.x += (left*self.getWidth())*self.zoom;
		self.y += (top*self.getHeight())*self.zoom;
		friendManager.updateAll();
	}
	self.dozoom = function(factor, coords) {
		if (typeof coords == 'undefined')
			coords = {x : self.getWidth()/2, y: self.getHeight()/2};
		var zoombefore = self.zoom;
		var zoomafter = self.zoom*factor;

		var px = coords['x']-$("#playfield").offset().left;
		var py = coords['y']-$("#playfield").offset().top;
		self.x = (px*zoombefore + self.x) - px*zoomafter;
		self.y = (py*zoombefore + self.y) - py*zoomafter;
		self.zoom = zoomafter;
		friendManager.updateAll();
	}
	self.resetCanvas = function() {
		var c = document.getElementById("c");
		c.width--;
		c.width++;
	}
};
