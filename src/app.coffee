

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
app.use express.session( { secret : 'Soilwork'} )
app.use app.router
app.use require('stylus').middleware(__dirname + '/../public')
app.use express.static(path.join(__dirname, '/../public'))
app.use passport.initialize()
app.use passport.session()

server = http.createServer(app)

server.listen app.get('port'), () ->
  console.log 'Express server listening on port ' + app.get('port')

#Connect Mongoose
MongoURI = process.env.MONGOLAB_URI ? 'mongodb://localhost/roguelife'
mongoose.connect MongoURI

#set up user documents
User = mongoose.model 'User', {
	steamName : String,
	username : String,
	email : String,
	password : String,
	description : String,
	experience : Number,
	tasks : Array
	#taskName : taskDescription
}	

#Ensure User is Authenticated
ensureAuthenticated = (req, res, next) ->
	if req.isAuthenticated()
		return next
	res.redirect('/login')
	return

#Passport needs to serialize to support persistent login sessions
passport.serializeUser (user, done) ->
	done null, user.id
	return

passport.deserializeUser (id, done) ->
	User.findById id, (err, user) ->
		done(err, user)
		return
	return

# #Setting Up OpenID for Steam Auth
# passport.use new SteamStrategy {
# 	returnURL: 'http://'+process.env.domain+'/auth/steam/return', 
# 	realm: 'http://'+process.env.domain+'/' 
# 	},(identifier, done) ->
# 		User.findByOpenID { openId: identifier }, (err, user) ->
# 		return done(err, user);

#Setting Up Local Auth
passport.use new LocalStrategy (username, password, done) ->
	User.findOne {username : username }, (err, user) ->
		if err
			console.log 'err', err
			return done(err)
		if !user
			console.log '!user', user
			return done(null, false)
		if user.password isnt password
			console.log 'pass', user.password, password
			return done(null, false)
		return
	return

# development only
if 'development' == app.get('env') 
  app.use express.errorHandler()








#BASIC ROUTES
app.get '/', (req, res) ->
	res.render 'index'
	return

app.get '/login', (req, res) ->
	res.render 'login'
	return

app.get '/dash', (req,res) ->
	res.render 'dash'
	return





#LOGIN/SIGNUP ROUTES

app.post '/signin', passport.authenticate('local'), (req, res) ->
	console.log 'req.user: ', req.user
	req.login user, (err) ->
		if err
			return next(err)
		return res.redirect '/'
	return



app.post '/signup', (req, res) ->
	console.log req.body
	user = new User {
		steamName : 'Not Linked'
		email : req.body.email,
		password : req.body.password,
		username : req.body.username,
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


# # Steam Authentication
# app.get '/auth/steam/', passport.authenticate('steam'), (req, res) ->
# 	res.redirect '/'
# 	return

# # {steamLogin : req.query} in return
# app.get '/auth/steam/callback',passport.authenticate('steam', {failureRedirect : '/login'}), (req, res) ->
# 	res.render '/', {steamLogin : req.query}
# 	return

# app.get '/auth/steam/return', (req, res) ->
# 	res.send req.query
# 	#res.render '/' # {steamLogin : req.query}
# 	return

app.get '/logout', (req, res) ->
	req.logout()
	res.redirect '/'
	return



