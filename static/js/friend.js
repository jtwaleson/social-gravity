function Friend(i) {
	this.id = i;
	this.div = null;
	this.x = rand(0, viewPort.getWidth());
	this.y = rand(40, viewPort.getHeight());
	this.n = 0;
	this.drawlines = false;
	this.visible = true;
	this.locked = false;
	this.draw();
	this.friends = null;
	this.info = null;
	this.followers = null;
	this.strongestConnections = {};
}
Friend.prototype.draw = function() {
	this.div = $("<div>")
		.attr('id',this.id)
		.text(this.id)
		.addClass('friend gray')
		.appendTo("#playfield")
		.disableSelection()
		.draggable({
			drag: function() {
				var p = friendManager.persons[$(this).attr('id')];
				p.locked = true;
				p.div.addClass('immovable');
				var c = viewPort.getOriginal({x: p.div.position().left, y: p.div.position().top});
				p.x = c.x;
				p.y = c.y;
				simulation.lock(p);
			},
			distance: 5
		})
		.click(function(e){
			var f = friendManager.persons[$(this).attr('id')];
			f.drawlines = !f.drawlines;
			friendManager.recalcPersonColors();
			friendManager.drawAllLines();
		}).dblclick(function() {
			var p = friendManager.persons[$(this).attr('id')];
			if (p.locked) {
				p.div.removeClass('immovable');
				p.locked = false;
				simulation.unlock(p);
			} else if (confirm('Start looking up '+$(this).text()+'?')) {
				protagonists.clear();
				protagonists.add($(this).text());
				$("#networkgenerator").click();
			}
		});
	this.update();
}
Friend.prototype.lock = function() {
	this.locked = true;
	this.div.addClass('immovable');
}
Friend.prototype.update = function () {
	var d = this.div;
	c = viewPort.getInflated({x: this.x, y: this.y});
	d.css('left',c['x']);
	d.css('top',c['y']);
	if (this.n >= simulation.settings['closefriendthreshold'] || this.locked) {
		if (!this.visible) {
			this.visible = true;
			d.fadeIn();
		}
	} else {
		if (this.visible && !this.locked) {
			this.visible = false;
			d.fadeOut();
		}
	}
}
Friend.prototype.calcStrongestConnections = function() {
	if (typeof this.strongconnections == 'undefined')
		return;
	this.strongestConnections = {};
	var m = 0;
	for (var i in this.strongconnections)
		m = Math.max(this.strongconnections[i], m);
	for (var i in this.strongconnections) {
		if (this.strongconnections[i] == m) {
			this.strongestConnections[i] = m;
		}
	}
}
Friend.prototype.setInfo = function (data) {
	this.hasinfo = true;
	if (this.div != null)
		this.div.html('<img src="'+data['profile_image_url']+'" title="'+data['screen_name']+'">');
	this.friendsRetrieved = 'friends' in data && 'ids' in data['friends'];
	this.prot = !this.friendsRetrieved;
	this.friends = {};
	
	if (this.prot)
		friendManager.amountprotected++;
	else {
		this.div.removeClass('halfgray');
		this.friendsRetrieved = true;
		for (var i in data['friends']['ids'])
			this.friends[data['friends']['ids'][i]] = 1;
	}
}
Friend.prototype.drawStrongLines = function(ctx) {
	for (var i in this.strongestConnections)
		this.drawLine(ctx, i);
}
Friend.prototype.drawLine = function(ctx, fid) {
	if (fid in friendManager.persons && friendManager.persons[fid].visible && this.visible) {
		var me = this.div.position();
		var o = friendManager.persons[ fid ].div.position();
		ctx.moveTo(me.left+this.div.width(), me.top);
		ctx.lineTo(o.left, o.top);
	}
}
