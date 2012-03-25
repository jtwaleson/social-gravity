function Friend(i) {
	this.id = i;
	this.div = null;
	this.x = rand(0, viewPort.getWidth());
	this.y = rand(40, viewPort.getHeight());
	this.n = 0;
	this.hasinfo = false;
	this.friendsRetrieved = false;
	this.followersRetrieved = false;
	this.drawlines = false;
	this.visible = true;
	this.locked = false;
	this.draw();
	this.friends = {};
	this.setInfo(sessionStorage.getItem('u_'+i), true);
	this.strongestConnections = {};
}
Friend.prototype.slimDown = function(data) {
	var f = ['id', 'protected', 'screen_name', 'description'];
	var info = {};
	for (var i in f)
		info[f[i]] = data[f[i]];
	return info;
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
Friend.prototype.setInfo = function (data, fromcache) {
	if (data == null)
		return;
	if (fromcache) {
		data = this.slimDown(JSON.parse(data));
	} else {
		data = this.slimDown(data);
		try {sessionStorage.setItem('u_'+data['id'], JSON.stringify(data)) } catch (e) {}
	}
	if (this.div != null)		
		this.div.text(data['screen_name']).removeClass('gray').addClass('halfgray').attr('title',data['description']);
	if (data['protected'] == "false")
		data['protected'] = false;
	if (data['protected'] == "true")
		data['protected'] = true;
	this.prot = data['protected'];
	if (this.prot)
		friendManager.amountprotected++;
	this.hasinfo = true;
	var count = 0;
}
Friend.prototype.setFriends = function (data) {
	var ids = data['result']['ids'];
	this.div.removeClass('halfgray');
	this.friends = {};
	for (var i in ids)
		this.friends[ids[i]] = 1;
	this.friendsRetrieved = true;
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
