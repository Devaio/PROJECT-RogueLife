

# Module dependencies.

express = require 'express' 
routes = require './../routes'
user = require './../routes/user'
http = require 'http'
path = require 'path'
passport = require 'passport'
fs = require 'fs'
LocalStrategy = require("passport-local").Strategy
mongoose = require 'mongoose'
GoogleStrategy = require('passport-google').Strategy
pathTasks = require './pathtasks'
moment = require 'moment'
io = require 'socket.io'
app = express()

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
	app.use express.cookieParser()
	app.use express.bodyParser()
	app.use express.session( { secret : 'catboard key'})
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
	done null, user._id
		

passport.deserializeUser (id, done) ->
	Character.findOne {_id : id}, (err, user) ->
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

#passport Google setup
passport.use new GoogleStrategy {
	returnURL: 'http://localhost:3000/auth/google/return',
	realm: 'http://localhost:3000'
	},
	(identifier, profile, done) ->
		console.log 'email', profile.emails[0]['value']
		console.log 'ID: ', identifier
		console.log 'PROF', profile
		Character.find {openId: identifier}, (err, user) ->
			done err, user[0]
			if user.length is 0
				newChar = new Character {
					openId: identifier,
					username: profile.displayName,
					email: profile.emails[0]['value']
				}
				newChar.save()
			return
		return

Character = mongoose.model 'Character', {
	username : {type : String, required : true, unique : true},
	openId : {type : String},
	email : {type: String, required : true, unique : true},
	password : {type : String},
	health : {type : Number, default : 100},
	currentHealth : {type : Number, default : 100},
	experience : {type : Number, default : 0},
	level : {type : Number, default : 1},
	maxExperience : {type : Number, default : 150},
	expPerc : {type : Number},
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

app.get '/logout', (req, res) ->
	req.logOut() 
	res.redirect '/'

#LOGIN/SIGNUP ROUTES

app.post '/signin', passport.authenticate('local'), (req, res) ->
	console.log req.user.username
	res.send {redirect : '/users/' + req.user._id, charData : req.user}

app.get '/charData', app.isAuthenticated, (req, res) ->
	res.send req.user


app.get '/users/:id', app.isAuthenticated, (req, res) ->
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
app.post '/chosenpath', app.isAuthenticated, (req, res) ->
	console.log 'user', req.user
	console.log 'BODY PATH', req.body.path
	Character.findOneAndUpdate {username : req.user.username}, {path : req.body.path}, (err, char) ->
		# char = char[0]
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
	Character.update {username : req.user.username}, {$push : {currentQuests : {questName : req.body.questName, startQuest: moment().format('X') }}}, (err, char) ->
	res.send 'updated'

app.post '/removeDaily', (req, res) ->
	Character.update {username : req.user.username}, {$pull : {dailies :  {dailyName : req.body.dailyName }}}, (err, char) ->
		if err
			console.log 'err remove', err
	res.send 'removed'

app.post '/updateDaily', (req, res) ->
	Character.update {username : req.user.username}, {$push : {dailies : {dailyName : req.body.dailyName, startDaily : moment().format('X') } }}, (err, char) ->
	res.send 'updated'


### GOOGLE ###
app.get '/auth/google', passport.authenticate 'google'

app.get '/auth/google/return', passport.authenticate 'google', {
	session: true,
	successRedirect: '/',
	failureRedirect: '/login'}

	

socketUpdateChar = (data, socket) ->
	Character.findOneAndUpdate {username : data.user.username}, {$inc : {experience : data.expGain }}, (err, char) ->
		
		console.log 'updateCHAR',char
		console.log 'charexp : ', char.experience
		levelUp = char.level
		expUp =  char.maxExperience
		expPerc =  (char.experience/char.maxExperience) * 100
		if char.experience > expUp
			Character.findOneAndUpdate {username : data.user.username}, {$inc : {level : 1, maxExperience : (levelUp * expUp)}}, (err, char) ->
			Character.findOneAndUpdate {username : data.user.username}, {$set : {experience : 0}},  (err, char) ->
		Character.findOneAndUpdate {username : data.user.username}, {$set : {expPerc : expPerc}}, (err, char) ->
		Character.find {username : data.user.username}, (err, char) ->
			charToUpdate = char[0]
			socket.emit 'updateChar', charToUpdate

### SOCKETS ###
user = {}
io.sockets.on 'connection', (socket) ->
	user[socket.id] = socket.id

	socket.on 'finishQuest', (data) ->
		Character.update {username : data.user.username}, {$pull : {currentQuests : {questName : data.questName} }}, (err, char) ->
		Character.update {username : data.user.username}, {$push : {completedQuests : data.questName}}, (err, char) ->
		socketUpdateChar(data, socket)

	socket.on 'finishDaily', (data) ->
		Character.update {username : data.user.username}, {$pull : {dailies : {dailyName : data.questName}} }, (err, char) ->
		socketUpdateChar(data, socket)

	socket.on 'damage', (data) ->
		Character.update {username : data.user.username}, {$set : {health : data.HP} }, (err, char) ->
			socketUpdateChar(data, socket)
		
	
	



