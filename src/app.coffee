

# Module dependencies.

express = require 'express' 
routes = require './../routes'
user = require './../routes/user'
http = require 'http'
path = require 'path'
passport = require "passport"
LocalStrategy = require("passport-local").Strategy
OpenIDStrategy = require('passport-openid').Strategy
SteamStrategy = require('passport-steam').Strategy
mongoose = require 'mongoose'
app = express();

# all environments
app.set 'port', process.env.PORT || 3000
app.set 'views', __dirname + '/../views'
app.set 'view engine', 'jade'
app.use express.favicon()
app.use express.logger('dev')
app.use express.bodyParser()
app.use express.methodOverride()
app.use express.cookieParser('your secret here')
app.use express.session()
app.use app.router
app.use require('stylus').middleware(__dirname + '/../public')
app.use express.static(path.join(__dirname, '/../public'))
app.use passport.initialize()
app.use passport.session()
#Connect Mongoose
mongoose.connect 'mongodb://<dbuser>:<dbpassword>@ds053148.mongolab.com:53148/heroku_app18992266'
#set up user documents
User = mongoose.model 'User', {
	steamName : String,
	charName : String,
	description : String,
	experience : Number
}	
#Ensure User is Authenticated
ensureAuthenticated = (req, res, next) ->
	if req.isAuthenticated()
		return next
	res.redirect('/login')
	return

#Passport needs to serialize to support persistent login sessions
passport.serializeUser (user, done) ->
	done null, user
	return

passport.deserializeUser (obj, done) ->
	dont null, obj
	return

# Setting Up OpenID for Steam Auth
passport.use new SteamStrategy {
	returnURL: 'http://roguelife.herokuapp.com/auth/steam/return',
	realm: 'http://roguelife.herokuapp.com/'
	},
  (identifier, done) ->
    User.findByOpenID { openId: identifier }, (err, user) ->
    	return done(err, user);
    return

# development only
if 'development' == app.get('env') 
  app.use express.errorHandler()


app.get '/', (req, res) ->
	# res.render 'index', {user : {charName : 'Rob'} } #does sample user for welcome
	res.render 'index'
	return
app.get '/login', (req, res) ->
	res.render 'login'
	return

server = http.createServer(app)

server.listen app.get('port'), () ->
  console.log 'Express server listening on port ' + app.get('port')

app.get '/auth/steam', passport.authenticate 'steam' , (req, res) ->
	return
app.get '/auth/steam/callback', passport.authenticate 'steam', {failureRedirect : '/login'}, (req, res) ->
	res.redirect('/')
	return


