


[express,jsmpeg] = (require x for x in ['express','../..'])

app = express()

app.set "view engine", "pug"
app.set "views", __dirname
app.use require('express-jquery')('/jq')

app.use jsmpeg app
app.get '/', (req, res) -> res.render 'stream-example'

# app.use require('serve-static')(__dirname, index:['stream-example.html'])



app.listen 9000
