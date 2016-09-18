
[jsmpeg,express,ffmpeg,jq] = 
	require x for x in ['../..','express','fluent-ffmpeg','express-jquery']

ffcmd = ffmpeg '1'
.inputFormat 'avfoundation'
.inputFPS 30
.size '640x480'
.format 'mpeg1video'
.videoBitrate '800k'
.output 'http://127.0.0.1:8082/secret/640/480/'
.on 'error', (err) -> console.log "An error occurred: #{err.message}"

app = express()
app.set 'view engine', 'pug'
app.set 'views', __dirname
app.use jq '/jq'

app.use jsmpeg app, {}, ffcmd

app.get '/', (req, res) -> res.render 'stream-example'
app.listen 9000

###
app.use require('serve-static')(__dirname, index:['stream-example.html'])
while true; do ffmpeg -f avfoundation -video_size 640x480 \
	-framerate 30 -i "1"  \
	-f mpeg1video -b 800k \
	http://localhost:8082/secret/640/480/ ; done
	ffmpeg.getAvailableFormats (err, formats) ->
  	console.log "Available formats: #{Object.keys(formats)}"
	  console.dir formats
	ffmpeg.getAvailableCodecs (err, codecs) ->
	  console.log 'Available codecs:'
	  console.dir codecs
	ffmpeg.getAvailableEncoders (err, encoders) ->
	  console.log 'Available encoders:'
	  console.dir encoders
	ffmpeg.getAvailableFilters (err, filters) ->
	  console.log "Available filters:"
	  console.dir filters
###


	


