

extend = require('util')._extend
array = require('ensure-array')

[fs,path,mime,ws,http] = (require x for x in ['fs','path','mime','ws','http'])
[width,height] = [320,240]

module.exports = (app, opts = {}) ->

	inited = false
	
	(req, res, next) ->
		
		if not inited
			
			extend opts,
				av: 1
				path: 'jsmpeg'
				STREAM_SECRET: process.argv[2] or 'secret'
				STREAM_PORT: process.argv[3] or 8082
				WEBSOCKET_PORT: process.argv[4] or 8084
				STREAM_MAGIC_BYTES: 'jsmp'
	
			# Websocket Server
			sockServer = new (ws.Server) port: opts.WEBSOCKET_PORT
			sockServer.on 'connection', (sock) ->
				# Send magic bytes and video size to the newly connected socket
				# struct { char magic[4]; unsigned short width, height;}
				streamHeader = new Buffer(8)
				streamHeader.write opts.STREAM_MAGIC_BYTES
				streamHeader.writeUInt16BE width, 4
				streamHeader.writeUInt16BE height, 6
				sock.send streamHeader, binary: true
				console.log "New WebSocket Connection (#{sockServer.clients.length} total)"
				sock.on 'close', (code, message) ->
					console.log "Disconnected WebSocket (#{sockServer.clients.length} total)"

			sockServer.broadcast = (data, opts) ->
				for i,client of @clients
					if client.readyState is 1 then client.send data, opts
					else console.log "Error: Client (#{i}) not connected."

			# HTTP Server to accept incomming MPEG Stream
			streamServer = http.createServer (req, res) ->
				params = req.url.substr(1).split('/')
				if params[0] is opts.STREAM_SECRET
					res.connection.setTimeout 0
					width 	= (params[1] or 320) | 0
					height 	= (params[2] or 240) | 0
					console.log "Stream Connected: #{req.socket.remoteAddress}:#{req.socket.remotePort} size:  #{width} x #{height}"
					req.on 'data', (data) -> sockServer.broadcast data, binary: true
				else
					console.log "Failed Stream Connection: #{req.socket.remoteAddress}:#{req.socket.remotePort} - wrong secret."
					response.end()
			.listen(opts.STREAM_PORT)

			console.log "Listening for MPEG Stream on http://127.0.0.1:#{opts.STREAM_PORT}/#{opts.STREAM_SECRET}/${width}/#{height}"
			console.log "Awaiting WebSocket connections on ws://127.0.0.1:#{opts.WEBSOCKET_PORT}/"

					# - Creating locals to easily include them in the views.
			extend app.locals,
				jsmpegpath: opts.path
				jsmpegwidth: width
				jsmpegheight: height
				jsmpegwsport: opts.WEBSOCKET_PORT
				
			views = array app.get('views')
			views.push __dirname
			app.set 'views', views
			
			console.log "views: #{app.get 'views'}"
			inited = true

		console.log "req.url is #{req.url}"
		if '/jsmpeg' is req.url
			console.log 'sending js'
			res.sendFile path.join path.dirname(__dirname), 'jsmpg.js'
		else
			next()
