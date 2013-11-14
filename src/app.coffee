

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
#require the Twilio module and create a REST client
# twilio (813) 358-5022
client = require('twilio')('AC36f2d68f70b9ad20c70ef3f94918f1f4', '87e6de7ba3dfd2bedef2555e04eae90e')
sendgrid = require('sendgrid')('Devaio', 'ragnarok14')
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
ip = process.env.IP ? 'http://localhost:3000'


passport.use new LocalStrategy (username, password, done) ->
	Character.findOne {username : username }, (err, user) ->
		if err
			return done(err)
		if !user
			return done(null, false, {message : 'Incorrect username'})
		if password isnt user.password
			return done(null, false, {message : 'Incorrect password'})
		return done(null, user)

#passport Google 
passport.use new GoogleStrategy {
	returnURL: ip+'/auth/google/return',
	realm: ip
	},
	(identifier, profile, done) ->
		process.nextTick () ->
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
	phone : {type : String},
	health : {type : Number, default : 100},
	currentHealth : {type : Number, default : 100},
	hpPerc : {type : Number, default : 100},
	experience : {type : Number, default : 0},
	level : {type : Number, default : 1},
	maxExperience : {type : Number, default : 150},
	expPerc : {type : Number},
	currentQuests : {type: Array, default : []},
	completedQuests : {type: Array, default : []},
	dailies : {type: Array, default:[]},
	preDaily :{type : Array, default : []},
	path : {type : String},
	avatar : {type : String}
}



# development only
if 'development' == app.get('env') 
	app.use express.errorHandler()

userNotification = (char, hp) ->
	if hp is 'low'
		sendgrid.send {
			to : char.email,
			from : 'admin@roguelife.herokuapp.com',
			subject : 'Your character has low health!',
			text : 'Greetings '+ char.username + '!\n Be careful!  Your character is running dangerously low on health.  Complete your daily tasks to avoid death!'
		}, (err, json) ->
			console.log 'JSON!!!:',json
		if char.phone
			client.sendMessage {
				to : char.phone
				from : '+18133585022',
				body : 'Greetings '+ char.username + '!\n Be careful!  Your character is running dangerously low on health.  Complete your daily tasks to avoid death!'
			}, (err, resData) ->
				console.log resData
	else
		sendgrid.send {
			to : char.email,
			from : 'admin@roguelife.herokuapp.com',
			subject : 'Your character has low health!',
			text : 'Greetings '+ char.username + '!\n It seems your lack of commitment has gotten your character killed! Your levels and experience have been reset.  Complete your daily tasks to avoid death!'
		}, (err, json) ->
			console.log 'JSON!!!:',json
		if char.phone
			client.sendMessage {
				to : char.phone
				from : '+18133585022',
				body : 'Greetings '+ char.username + '!\n It seems your lack of commitment has gotten your character killed! Your levels and experience have been reset. Complete your daily tasks to avoid death!'
			}, (err, resData) ->
				console.log resData

#BASIC ROUTES
app.get '/', (req, res) ->
	console.log req.user
	res.render 'index', {userCharacter : req.user}
	

app.get '/login', (req, res) ->
	res.render 'login'

app.get '/logout', (req, res) ->
	req.logOut() 
	res.redirect '/'

app.get '/about', (req, res) ->
	res.render 'about', {userCharacter : req.user}

app.get '/topcharacters', (req, res) ->
	Character.find {}, (err, topChar) ->
		topChar.sort (a, b) ->
			return b.level - a.level
		global.leaderChars = topChar
			
			

	res.render 'topcharacters', {topChar : leaderChars}

#LOGIN/SIGNUP ROUTES

app.post '/signin', passport.authenticate('local'), (req, res) ->
	console.log req.user.username
	res.send {redirect : '/users/' + req.user._id, charData : req.user}

app.get '/charData', app.isAuthenticated, (req, res) ->
	res.send req.user

app.get '/users', app.isAuthenticated, (req, res) -> #redirects Google signins to user page
	res.redirect '/users/'+req.user._id

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
		console.log 'PHONE STUFS', req.body.phone.replace /[^\w\s]/gi, ''
		if user
			res.send {message : 'Already a user!'}
		else
			newUser = new Character {
				email : req.body.email,
				password : req.body.password,
				username : req.body.username,
				phone : '+1'+req.body.phone.replace /[^\w\s]/gi, ''
			}
			newUser.save()
			console.log 'UserID', newUser._id
			res.redirect '/'




# Choosing habit path
app.post '/chosenpath', app.isAuthenticated, (req, res) ->
	console.log 'user', req.user
	console.log 'BODY PATH', req.body.path
	Character.findOneAndUpdate {username : req.user.username}, {path : req.body.path, avatar : req.body.path}, (err, char) ->
		pushDailyName = randomDaily( pathTasks.Dailies, char.path )
		Character.findOneAndUpdate {username : req.user.username}, {$set : {preDaily : [{preDailyName : pushDailyName, preDailyStart : moment().format('X'), finished : false}]}}, (err, char) ->
			char['dailies'].push pushDaily
			char.markModified('dailies')
			char.save()
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
	successRedirect: '/users/',
	failureRedirect: '/login'}

	

socketUpdateChar = (data, socket) ->
	Character.findOneAndUpdate {username : data.user.username}, {$inc : {experience : data.expGain }}, (err, char) ->
		levelUp = char.level
		expUp =  char.maxExperience
		expPerc =  (char.experience/char.maxExperience) * 100
		hpPerc = (char.currentHealth/char.health)*100
		if char.experience > expUp && char.currentHealth<(char.health - 5)
			Character.findOneAndUpdate {username : data.user.username}, {$inc : {health : 5, currentHealth : 5, level : 1, maxExperience : Math.floor((levelUp * expUp)*.5)}, $set : {experience : 0, expPerc : 1}}, (err, char) ->
		else if char.experience > expUp
			Character.findOneAndUpdate {username : data.user.username}, {$inc : {health : 5, level : 1, maxExperience : (levelUp * expUp)*.5}, $set : {experience : 0, expPerc : 1}}, (err, char) ->
		Character.findOneAndUpdate {username : data.user.username}, {$set : {expPerc : expPerc, hpPerc : hpPerc}}, (err, char) ->

		Character.find {username : data.user.username}, (err, char) ->
			charToUpdate = char[0]
			socket.emit 'updateChar', charToUpdate

randomDaily = (randDaily, path) ->
	pathList = randDaily[path]
	listLength = pathList.length
	randPick = Math.floor((Math.random()*listLength))
	newDaily = pathList[randPick]
	return newDaily	


### SOCKETS ###
user = {}
io.sockets.on 'connection', (socket) ->
	user[socket.id] = socket.id

	socket.on 'finishQuest', (data) -> # for checking off quests
		Character.findOneAndUpdate {username : data.user.username}, {$pull : {currentQuests : {questName : data.questName} }}, (err, char) ->
		Character.findOneAndUpdate {username : data.user.username}, {$push : {completedQuests : data.questName}}, (err, char) ->
		socketUpdateChar(data, socket)

	socket.on 'finishDaily', (data) -> #for checking off dailies
		Character.findOne {username : data.user.username}, {}, (err, char) ->
			char['dailies'].forEach (daily) ->
				if daily.dailyName is data.questName
					daily.finished = true
					daily.startDaily = moment().format('X')
					char.markModified 'dailies'
					char.save()
					socketUpdateChar(data, socket)
	socket.on 'finishpreDaily', (data) ->
		Character.findOne {username : data.user.username}, {}, (err, char) ->
			char['preDaily'].forEach (daily) ->
				if daily.preDailyName is data.questName
					daily.finished = true
					daily.startPreDaily = moment().format('X')
					char.markModified 'preDaily'
					char.save()
					socketUpdateChar(data, socket)
	socket.on 'damage', (data) ->
		Character.findOneAndUpdate {username : data.user.username}, {$inc : {currentHealth : -15}}, (err, char) ->
		Character.findOne {username : data.user.username}, {}, (err, char) ->
			char['dailies'].forEach (daily) -> #loops through dailies array and sets timer
				daily.startDaily = moment().format('X')
				daily.finished = false
			char['preDaily'].forEach (daily) ->
				daily.startPreDaily = moment().format('X')
				daily.finished = false
			char['hpPerc'] = (char.currentHealth / char.health) * 100
			if char.hpPerc <= 33 && char.hpPerc > 0
				userNotification(char)
			char.markModified 'preDaily'
			char.markModified 'dailies'
			char.markModified 'hpPerc'
			char.save()
			socket.emit 'damageTaken', char
	socket.on 'daily', (data) ->
		pushDaily = randomDaily(pathTasks.Dailies, data.user.path)
		Character.findOneAndUpdate {username : data.user.username}, {$set : {preDaily : [{preDailyName : pushDaily, preDailyStart : moment().format('X'), finished : false}]}}, (err, char) ->

	socket.on 'death', (data) ->
		console.log 'DATADEATH', data
		Character.findOneAndUpdate {username : data.username}, {$set : {currentHealth : 100, health : 100, level : 1, experience : 0, maxExperience : 150, hpPerc : 100, expPerc : 0}}, (err, char) ->
			console.log 'deadCHAR', char
			userNotification(char)
			socket.emit 'dead', char

