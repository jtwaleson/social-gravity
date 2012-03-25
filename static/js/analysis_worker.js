var friends = {};
var connections = {};
var locked = {};
var settings = {};
var grid = {}
var dst = 400.0;
var halfdst = dst/2;
var attraction = 1.0;
var attraction2 = 1.0;
var repulsion = 0.1;
var movetocenter = 1.0;
var numberoffriends = 0;

var iteration = 0;

onmessage = function(d) {
    data = d['data'];
    if ('run' in data) {
        iteration = 0;
        run(true);
    } else if ('iter' in data) {
	run(false);
    } else if ('stop' in data) {
        running = false;
    } else if ('friends' in data) {
        friends = data['friends'];
	locked = {};
        numberoffriends = 0;
        for (var i in friends) {
		addRemoveFromGrid(i, getCoords(i), true);
		numberoffriends++;
        }
    } else if ('connections' in data) {
        connections = data['connections'];
    } else if ('unlock' in data) {
	delete locked[data['unlock']];
    } else if ('lock' in data) {
        locked[data['lock']] = data;
	friends[data['lock']]['x'] = data['x'];
	friends[data['lock']]['y'] = data['y'];
    } else if ('settings' in data) {
	grid = {};
	dst = data['settings']['dst'];
	halfdst = dst/2;
	attraction = data['settings']['attraction'];
	attraction2 = data['settings']['attraction2'];
	repulsion = data['settings']['repulsion'];
	movetocenter = data['settings']['movetocenter'];
	for (var i in friends)
		addRemoveFromGrid(i, getCoords(i), true);
    }
    
}

function getFriends(c, x, y) {
	try {
		return grid[c['x']+x][c['y']+y];
	} catch (err) {
		return {};
	}
}
function getNearFriends(id) {
	fr = {};
	c = getCoords(id);
	for (var x = -1; x <= 1; x++) {
		for (var y = -1; y <= 1; y++) {
			for (f in getFriends(c, x, y))
				if (inDistance(id, f))
					fr[f] = 0;
		}
	}
	return fr;
}
function inDistance(id1,id2) {
	return ( Math.pow(friends[id1]['x'] - friends[id2]['x'], 2)
                 + Math.pow(friends[id1]['y'] - friends[id2]['y'], 2))
               < dst*dst;
}
function getCoords(id) {
	var c = {};
	c['x'] = Math.round(friends[id]['x']/dst);
	c['y'] = Math.round(friends[id]['y']/dst);
	return c;
}
function addRemoveFromGrid(id, c, add) {
	try {
		if (add) {
			grid[c['x']][c['y']][id] = 1;
		} else {
			if (id in grid[c['x']][c['y']])
				delete grid[c['x']][c['y']][id];
		}
	} catch (err) {
		if (typeof grid[c['x']] == 'undefined')
			grid[c['x']] = {}
		if (typeof grid[c['x']][c['y']] == 'undefined')
			grid[c['x']][c['y']] = {}
		addRemoveFromGrid(id, c, add);
	}
}


function move(id, x, y, amount, proportional) {
	
	if (!(id in friends))
		return;
	if (id in locked)
		return;
	if (amount == 0)
		return;
	
	dx = x - friends[id]['x'];
	dy = y - friends[id]['y'];
	
	if (dx == 0 && dy == 0)
		return;
	if (dx == 0)
		dx = 0.001;
	if (dy == 0)
		dy = 0.001;

	oldpos = getCoords(id);

	d = dx*dx+dy*dy;
	
	if (proportional) {
		if (d < (dst*dst)) {
			if (d < dst)
				d = halfdst;
			amount = amount*(halfdst*halfdst)/d;
		} else {
			return;
		}
	}
	

	if (true){ //d > (dst*dst)/10) {
		if (dx*dx > dy*dy) {
			px = 1;
			py = Math.abs(dy/dx);
		} else {
			px = Math.abs(dx/dy);
			py = 1;
		}
		if (dx < 0)
			px *= -1;
		if (dy < 0)
			py *= -1;
			
		m_x = amount*px;
		m_y = amount*py;
		
		if (Math.abs(m_x) > Math.abs(dx))
			m_x = dx;
		if (Math.abs(m_y) > Math.abs(dy))
			m_y = dy;

		friends[id]['x'] -= m_x;
		friends[id]['y'] -= m_y;
	}
	newpos = getCoords(id);
	if (oldpos['x'] != newpos['x'] || oldpos['y'] != newpos['y']) {
		addRemoveFromGrid(id, oldpos, false);
		addRemoveFromGrid(id, newpos, true);
	}
}

var k = 0;

function run(returnfriends) {
	if (iteration < 5){
		for (var i in friends) {
			for (var j in connections[i]) {
				move(j, friends[i]['x'], friends[i]['y'], -connections[i][j], false);
			}
			friends[i]['n'] = 0;
			for (var j in getNearFriends(i)) {
				move(j, friends[i]['x'], friends[i]['y'], repulsion, true);
				if (i in connections && j in connections[i])
					friends[i]['n']++;

			}
			move(i, 0.0, 0.0, -movetocenter, false);
		}
		if (returnfriends)
			postMessage({friends: friends});
		else {
			iteration++;
			postMessage({});
		}
	} else {
		setTimeout(function(){postMessage({})}, 100);
	}
}
