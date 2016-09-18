
global[x] = require y.replace('@',x) for x,y of {
	'fs','path','mime','ws','http'
	_: 'underscore', array:'ensure-@'
}

[width,height] = [640,480]
log = console.log

class JSMPEG
	constructor: (@app, @opts = {}, @ffcmd) ->

		_.defaults @opts,
			path: '/jsmpeg'
			stream_secret: 'secret'
			stream_port: 8082
			websocket_port: 8084
			stream_magic_bytes: 'jsmp'

		# Websocket Server
		sockServer = new (ws.Server) port: @opts.websocket_port
		sockServer.on 'connection', (sock) =>
			# Send magic bytes and video size to the newly connected socket
			# struct { char magic[4]; unsigned short width, height;}
			streamHeader = new Buffer(8)
			streamHeader.write @opts.stream_magic_bytes
			streamHeader.writeUInt16BE width, 4
			streamHeader.writeUInt16BE height, 6
			sock.send streamHeader, binary: true
			log "New WebSocket Connection (#{sockServer.clients.length} total)"
			sock.on 'close', (code, msg) ->
				log "Disconnected WebSocket (#{sockServer.clients.length} total)"

		sockServer.broadcast = (data, opts) ->
			for i,client of @clients
				return log "Error: Client (#{i}) not connected." if client.readyState isnt 1
				client.send data, opts
		
		log "Awaiting WebSocket conns on ws://127.0.0.1:#{@opts.websocket_port}/"
		
		# HTTP Server to accept incomming MPEG Stream
		streamServer = http.createServer (req, res) =>
			params = req.url.substr(1).split '/'
			if params[0] is @opts.stream_secret
				res.connection.setTimeout 0
				[w,h] = [params[1] or width,params[2] or height]
				log "Stream Connected: #{req.socket.remoteAddress}:#{req.socket.remotePort} size:  #{w} x #{h}"
				req.on 'data', (d) -> sockServer.broadcast d, binary: true
			else
				log "Failed Stream Connection: #{req.socket.remoteAddress}:#{req.socket.remotePort} - wrong secret."
				res.end()
		.listen @opts.stream_port, (err) =>
			log err? and err or "Listening for MPEG Stream on http://127.0.0.1:#{@opts.stream_port}/#{@opts.stream_secret}/${width}/#{height}"
			if not err? and @ffcmd?
				log 'Runnning ffmpeg command...'
				@ffcmd.run()
		
		# - Creating locals to easily include them in the views.
		_.extend @app.locals,
			jsmpegpath: @opts.path
			jsmpegwidth: width
			jsmpegheight: height
			jsmpegwsport: @opts.websocket_port
		
		views = array @app.get('views')
		views.push __dirname
		@app.set 'views', views
		
		log "views: #{@app.get 'views'}"

	run: (req, res, next) ->
		
		log "req.url is #{req.url}"
		if '/jsmpeg' is req.url
			res.sendFile path.join path.dirname(__dirname), 'jsmpeg', 'jsmpg.js'
		else
			next()

module.exports = (app,opts,ff) ->
	js = new JSMPEG(app,opts,ff)
	js.run
	
