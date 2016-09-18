if process.argv.length < 3
	console.log 'Usage: node stream-server.js <secret> [<stream-port> <websocket-port>]'
	process.exit()
STREAM_SECRET = process.argv[2]
STREAM_PORT = process.argv[3] or 8082
WEBSOCKET_PORT = process.argv[4] or 8084
STREAM_MAGIC_BYTES = 'jsmp'
# Must be 4 bytes
[width,height] = [320,240]
# Websocket Server
socketServer = new (require('ws').Server) port: WEBSOCKET_PORT
socketServer.on 'connection', (socket) ->
	# Send magic bytes and video size to the newly connected socket
	# struct { char magic[4]; unsigned short width, height;}
	streamHeader = new Buffer(8)
	streamHeader.write STREAM_MAGIC_BYTES
	streamHeader.writeUInt16BE width, 4
	streamHeader.writeUInt16BE height, 6
	socket.send streamHeader, binary: true
	console.log 'New WebSocket Connection (' + socketServer.clients.length + ' total)'
	socket.on 'close', (code, message) ->
		console.log 'Disconnected WebSocket (' + socketServer.clients.length + ' total)'

socketServer.broadcast = (data, opts) ->
	for i of @clients
		if @clients[i].readyState == 1
			@clients[i].send data, opts
		else
			console.log 'Error: Client (' + i + ') not connected.'

# HTTP Server to accept incomming MPEG Stream
streamServer = require('http').createServer (request, response) ->
	params = request.url.substr(1).split('/')
	if params[0] == STREAM_SECRET
		response.connection.setTimeout 0
		width = (params[1] or 320) | 0
		height = (params[2] or 240) | 0
		console.log 'Stream Connected: ' + request.socket.remoteAddress + ':' + request.socket.remotePort + ' size: ' + width + 'x' + height
		request.on 'data', (data) ->
			socketServer.broadcast data, binary: true
	else
		console.log 'Failed Stream Connection: ' + request.socket.remoteAddress + request.socket.remotePort + ' - wrong secret.'
		response.end()
.listen(STREAM_PORT)

console.log 'Listening for MPEG Stream on http://127.0.0.1:' + STREAM_PORT + '/<secret>/<width>/<height>'
console.log 'Awaiting WebSocket connections on ws://127.0.0.1:' + WEBSOCKET_PORT + '/'
