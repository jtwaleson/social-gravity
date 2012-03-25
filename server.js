var http = require('http');
var mongo = require('mongodb');
var Db = mongo.Db, Server = mongo.Server, Connection = mongo.Connection;
var url = require('url');
var qs = require('querystring');

var host = process.env['MONGO_NODE_DRIVER_HOST'] != null ? process.env['MONGO_NODE_DRIVER_HOST'] : 'localhost';
var port = process.env['MONGO_NODE_DRIVER_PORT'] != null ? process.env['MONGO_NODE_DRIVER_PORT'] : Connection.DEFAULT_PORT;

console.log("Connecting to " + host + ":" + port);
var db = new Db('socialgraph', new Server(host, port, {}));

function find(response, db, resid) {
	db.collection('cache', function(err, collection) {
		console.log('looking in database collection cache for resid: '+resid);
		collection.findOne({resid: resid}, function(err, result) {
			if (result != null) {
				response.writeHead(200, {'Cache-Control': 'max-age=432000', 'Content-Type': 'application/json; charset=utf-8'});
				response.end(JSON.stringify(result));
			} else {
				response.writeHead(404);
				response.end('notfound');
			}
		});
	});
}
function store(response, db, resid, request) {
	var body = '';
	request.on('data', function(data) {
		body += data;
	});
	request.on('end', function() {
		body = JSON.parse(qs.parse(body)['data']);
		db.collection('cache', function(err, collection) {
			body['resid'] = resid;
			body['insertedon'] = new mongo.Timestamp();
			collection.insert(body); 
			response.writeHead(200);
			response.end('ok');
		});
	});
}

db.open(function(err,db){
	http.createServer(function(request, res) {
		var path = url.parse(request.url).path.split('/');
		if (path.length == 3) {
			var resid = path[2];
			if (request.method == 'GET') {
				find(res, db, resid);
				return;
			} else if (request.method == 'POST') {
				store(res, db, resid, request);
				return;
			}
		}
		res.writeHead(400);
		res.end('invalid');
	}).listen(82);
});
