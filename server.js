var http = require('http');
var mongo = require('mongodb');
var Db = mongo.Db, Server = mongo.Server, Connection = mongo.Connection;
var url = require('url');
var qs = require('querystring');

var host = process.env['MONGO_NODE_DRIVER_HOST'] != null ? process.env['MONGO_NODE_DRIVER_HOST'] : 'localhost';
var port = process.env['MONGO_NODE_DRIVER_PORT'] != null ? process.env['MONGO_NODE_DRIVER_PORT'] : Connection.DEFAULT_PORT;

var db = new Db('socialgraph', new Server(host, port, {}));

// There are two types of entries: users (profile+friendlist) and followerlists


function find(response, db, type, id) {
	var searchquery = {id: id}
	if (type == 'userbyname') {
		type = 'user';
		searchquery = {lower_screen_name: id.toLowerCase()};
	}
	db.collection(type, function(err, collection) {
		collection.findOne(searchquery, function(err, result) {
			if (result != null) {
				response.writeHead(200, {'Cache-Control': 'max-age=432000', 'Content-Type': 'application/json; charset=utf-8'});
				if (type == 'followers')
					response.end(JSON.stringify(result));
				else
					response.end(JSON.stringify([result]));
			} else {
				response.writeHead(404);
				response.end('not found');
			}
		});
	});
}
function store(response, db, type, id, request) {
        var body = '';
        request.on('data', function(data) {
                body += data;
        });
        request.on('end', function() {
                body = JSON.parse(qs.parse(body)['data']);
                db.collection(type, function(err, collection) {
                        collection.remove({id:id});
                        body['id'] = id;
			if ('screen_name' in body)
				body['lower_screen_name'] = body['screen_name'].toLowerCase();
                        collection.insert(body); 
                        response.writeHead(200);
                        response.end('ok');
                });
        });
}

db.open(function(err,db){
	http.createServer(function(request, response) {
		var path = url.parse(request.url).path.split('/');
		if (path.length == 4) {
			var type = path[2];
			var id = path[3];
			
			if (request.method == 'GET') {
				find(response, db, type, id);
				return;
			} else if (request.method == 'POST') {
				store(response, db, type, id, request);
				return;
			}
		}
		res.writeHead(400);
		res.end('invalid');
	}).listen(82);
});
