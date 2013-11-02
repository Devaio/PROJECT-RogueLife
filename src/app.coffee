

# Module dependencies.

express = require 'express' 
routes = require './../routes'
user = require './../routes/user'
http = require 'http'
path = require 'path'
passport = require 'passport'
fs = require 'fs'
LocalStrategy = require("passport-local").Strategy
OpenIDStrategy = require('passport-openid').Strategy
SteamStrategy = require('passport-steam').Strategy
mongoose = require 'mongoose'
app = express();
pathTasks = require './pathtasks'


# all environments
app.set 'port', process.env.PORT || 3000
app.set 'views', __dirname + '/../views'
app.set 'view engine', 'jade'
app.use express.favicon()
app.use express.logger('dev')
app.use require('stylus').middleware(__dirname + '/../public')
app.use express.methodOverride()
app.configure () ->
	app.use express.static(path.join(__dirname, '/../public'))
	app.use express.cookieParser('catboard key')
	app.use express.bodyParser()
	app.use express.session()
	app.use passport.initialize()
	app.use passport.session()
	app.use app.router

server = http.createServer(app)

server.listen app.get('port'), () ->
  console.log 'Express server listening on port ' + app.get('port')

MongoURI = process.env.MONGOLAB_URI ? 'mongodb://localhost/roguelife'
mongoose.connect MongoURI


### PASSPORT ###
#Ensure User is Authenticated
app.isAuthenticated = (req, res, next) ->
	if req.isAuthenticated()
		return next()
	res.redirect '/login'

#Passport needs to serialize to support persistent login sessions
passport.serializeUser (user, done) ->
	done null, user.id
	

passport.deserializeUser (id, done) ->
	Character.findById id, (err, user) ->
		done err, user
		
	

#Setting Up Local Auth
passport.use new LocalStrategy (username, password, done) ->
	Character.findOne {username : username }, (err, user) ->
		if err
			return done(err)
		if !user
			return done(null, false, {message : 'Incorrect username'})
		if password isnt user.password
			return done(null, false, {message : 'Incorrect password'})
		return done(null, user)
	

#Setting Up passport for Steam Auth
passport.use new SteamStrategy {
	returnURL: 'http://'+process.env.domain+'/auth/steam/return', 
	realm: 'http://'+process.env.domain+'/' 
	},(identifier, done) ->
		User.findByOpenID { openId: identifier }, (err, user) ->
		if err
			return done(err)
		if !user
			return done(null, false, {message : 'Incorrect username'})
		if password isnt user.password
			return done(null, false, {message : 'Incorrect password'})
		return done(null, user)

Character = mongoose.model 'Character', {
	username : {type : String, required : true, unique : true},
	email : {type: String, required : true, unique : true},
	password : {type : String, required : true},
	health : {type : Number, default : 100},
	currentHealth : {type : Number, default : 100}
	mana : {type : Number, default : 50},
	currentMana : {type : Number, default : 50},
	experience : {type : Number, default : 0},
	level : {type : Number, default : 1},
	currentQuests : {type: Array, default : []},
	completedQuests : {type: Array, default : []},
	path : {type : String}
	avatar : {type : String}
}


# development only
if 'development' == app.get('env') 
  app.use express.errorHandler()



#BASIC ROUTES
app.get '/', (req, res) ->
	res.render 'index'
	

app.get '/login', (req, res) ->
	res.render 'login'
	






#LOGIN/SIGNUP ROUTES

app.post '/signin', passport.authenticate('local'), (req, res) ->
	console.log req.user.username
	res.send {redirect : '/dash', charData : req.user}

app.get '/charData', app.isAuthenticated, (req, res) ->
	res.send req.user


app.get '/dash', app.isAuthenticated, (req, res) ->
	console.log 'USER IN DASH', req.user
	Character.find {username : req.user.username}, (err, data) ->
		if err
			console.log 'error', err
		else
			console.log 'char', data
			res.render 'dash', { userCharacter : data[0], dailies : pathTasks.dailies }



app.get '/login', (req, res) ->
	res.render 'login'

### FIND A SOLUTION FOR ME - REDIRECT IN SIGNIN POST ROUTES TO /UNDEFINED ###
app.get '/undefined', (req, res) ->
	res.redirect '/dash'


app.post '/signup', (req, res) ->
	Character.findOne {username : req.body.username}, (err, user) ->
		if user
			res.send 'Already a user!'
		else
			newUser = new Character {
				email : req.body.email,
				password : req.body.password,
				username : req.body.username
			}
			newUser.save()
			console.log 'UserID', newUser._id
			res.send 'success!'
	



# Choosing habit path
app.post '/chosenpath', (req, res) ->
	console.log 'user', req.user
	console.log 'BODY PATH', req.body.path
	Character.update {username : req.user.username}, {$set : {path : req.body.path}}, (err, char) ->
		char = char[0]
		console.log 'CHAR!!!', char
		if err
			console.log 'error choosepath', err
	res.send 'success!'
	
app.post '/addQuest', (req, res) ->
	Character.update {username : req.user.username}, {$push : {currentQuests : req.body.currentQuest}}, (err, char) ->
		if err
			console.log 'error questadd', err
	res.send 'new quest!'





# Steam Authentication
app.get '/auth/steam/', passport.authenticate('steam'), (req, res) ->
	res.redirect '/'
	return
 
# {steamLogin : req.query} in return
app.get '/auth/steam/callback',passport.authenticate('steam', {failureRedirect : '/login'}), (req, res) ->
	res.render '/', {steamLogin : req.query}
	return

app.get '/auth/steam/return', (req, res) ->
	res.send req.query
	#res.render '/' # {steamLogin : req.query}
	return

app.get '/users/logout', (req, res) ->
	req.session.destroy (err) ->
	res.redirect '/'

	



