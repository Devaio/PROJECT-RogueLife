

# Module dependencies.

express = require 'express' 
routes = require './../routes'
user = require './../routes/user'
http = require 'http'
path = require 'path'
passport = require 'passport'
fs = require 'fs'
LocalStrategy = require("passport-local").Strategy
SteamStrategy = require('passport-steam').Strategy
mongoose = require 'mongoose'
app = express();
pathTasks = require './pathtasks'
moment = require 'moment'
io = require 'socket.io'

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
io = io.listen(server);

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
	returnURL: 'http://127.0.0.1:3000/auth/steam/return', 
	realm: 'http://http://127.0.0.1:3000/' 
	}, (identifier, profile, done) ->
		# Character.findByOpenID { openId: identifier }, (err, user) ->
		# if err
		# 	return done(err)
		# if !user
		# 	return done(null, false, {message : 'Incorrect username'})
		# if password isnt user.password
		# 	return done(null, false, {message : 'Incorrect password'})
		# return done(null, user)
		profile.identifier = identifier
		console.log 'prof', profile
		return done(null, profile)

Character = mongoose.model 'Character', {
	username : {type : String, required : true, unique : true},
	email : {type: String, required : true, unique : true},
	password : {type : String, required : true},
	openID : {type : String},
	health : {type : Number, default : 100},
	currentHealth : {type : Number, default : 100}
	mana : {type : Number, default : 50},
	currentMana : {type : Number, default : 50},
	experience : {type : Number, default : 0},
	level : {type : Number, default : 1},
	currentQuests : {type: Array, default : []},
	completedQuests : {type: Array, default : []},
	dailies : {type: Array, default:[]},
	path : {type : String},
	avatar : {type : String}
}


# development only
if 'development' == app.get('env') 
  app.use express.errorHandler()



#BASIC ROUTES
app.get '/', (req, res) ->
	res.render 'index', {userCharacter : req.user}
	

app.get '/login', (req, res) ->
	res.render 'login'
	






#LOGIN/SIGNUP ROUTES

app.post '/signin', passport.authenticate('local'), (req, res) ->
	console.log req.user.username
	res.send {redirect : '/users/' + req.user._id, charData : req.user}

app.get '/charData', app.isAuthenticated, (req, res) ->
	res.send req.user


app.get '/users/:id', app.isAuthenticated, (req, res) ->
	console.log 'USER IN DASH', req.user
	Character.find {username : req.user.username}, (err, data) ->
		if err
			console.log 'error', err
		else
			console.log 'char', data
			res.render 'dash', { userCharacter : data[0], dailies : pathTasks.dailies }



app.get '/login', (req, res) ->
	res.render 'login'


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
			passport.authenticate 'local', (req, res) ->
				res.redirect '/'
	



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
	

app.post '/removeQuest', (req, res) ->
	Character.update {username : req.user.username}, {$pull : {currentQuests : {questName : req.body.questName}}}, (err, char) ->
		if err
			console.log 'err remove', err
	res.send 'removed'

app.post '/updateQuest', (req, res) ->
	Character.update {username : req.user.username}, {$push : {currentQuests : {questName : req.body.questName, startQuest: moment().format('lll') }}}, (err, char) ->
	res.send 'updated'

app.post '/removeDaily', (req, res) ->
	Character.update {username : req.user.username}, {$pull : {dailies :  req.body.dailyName}}, (err, char) ->
		if err
			console.log 'err remove', err
	res.send 'removed'

app.post '/updateDaily', (req, res) ->
	Character.update {username : req.user.username}, {$push : {dailies : req.body.dailyName }}, (err, char) ->
	res.send 'updated'


# Steam Authentication
app.get '/auth/steam/', passport.authenticate('steam')
 
# {steamLogin : req.query} in return
app.get '/auth/steam/callback', passport.authenticate('steam'), (req, res) ->
	console.log 'auth steam cb', req.user
	res.redirect '/'
	return

app.get '/auth/steam/return', (req, res) ->
	console.log 'steam user', req.user
	res.redirect '/' # {steamLogin : req.query}
	return

app.get '/logout', (req, res) ->
	req.logOut() 
	res.redirect '/'
	
### SOCKETS ###
user = {}
io.sockets.on 'connection', (socket) ->
	user[socket.id] = socket.id

	io.sockets.emit 'connected', {id : socket.id}
	socket.on 'updateDaily', (dailyName) ->########here!


	



