

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
MongoURI = process.env.MONGOLAB_URI ? 'mongodb://localhost/roguelife'
mongoose.connect MongoURI
#set up user documents
User = mongoose.model 'User', {
	steamName : String,
	charName : String,
	email : String,
	password : String,
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
	realm: 'http://roguelife.herokuapp.com/',
	profile : true
	},
  (identifier, profile, done) ->
    User.findByOpenID { openId: identifier, userProf : profile }, (err, user) ->
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

app.post '/auth/steam', passport.authenticate 'steam' , (req, res) ->
	return

app.post '/auth/steam/return', passport.authenticate 'steam', {successRedirect : '/', failureRedirect : '/login'}, (req, res) ->
	res.redirect '/', {steamLogin : req.query}
	return

app.post '/signup', (req, res) ->
	console.log req.body
	user = new User {
		steamName : 'Not Linked'
		email : req.body.emailSignup,
		password : req.body.passwordSignup,
		charName : req.body.usernameSignup,
		description : ' the Ambitious',
		experience : 0 
	}
	console.log user._id
	user.save (err) ->
		if err
			res.send err
		else
			User.findById user['_id'], (err, userData) ->
				res.send {success : "Success!", user : userData}
	return
