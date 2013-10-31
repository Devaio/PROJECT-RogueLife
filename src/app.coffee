

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

# all environments
app.set 'port', process.env.PORT || 3000
app.set 'views', __dirname + '/../views'
app.set 'view engine', 'jade'
app.use express.favicon()
app.use passport.initialize()
app.use passport.session()
app.use express.logger('dev')
app.use express.bodyParser()
app.use express.methodOverride()
app.use express.cookieParser('your secret here')
app.use express.session()
app.use app.router
app.use require('stylus').middleware(__dirname + '/../public')
app.use express.static(path.join(__dirname, '/../public'))


server = http.createServer(app)

server.listen app.get('port'), () ->
  console.log 'Express server listening on port ' + app.get('port')

MongoURI = process.env.MONGOLAB_URI ? 'mongodb://localhost/roguelife'
mongoose.connect MongoURI


# #Setting Up OpenID for Steam Auth
# passport.use new SteamStrategy {
# 	returnURL: 'http://'+process.env.domain+'/auth/steam/return', 
# 	realm: 'http://'+process.env.domain+'/' 
# 	},(identifier, done) ->
# 		User.findByOpenID { openId: identifier }, (err, user) ->
# 		return done(err, user);

Character = mongoose.model 'Character', {
    username : {type : String, required : true, unique : true},
    email : {type: String, required : true, unique : true},
    password : {type : String, required : true},
    health : {type : Number, default : 100},
    mana : {type : Number, default : 50},
    experience : {type : Number, default : 0},
    tasks : {type: Array, default : []}
}

#Ensure User is Authenticated
app.isAuthenticated = (req, res, next) ->
    if req.isAuthenticated()
        return next()
    res.redirect "/login"
    return

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
	Character.findById id, (err, user) ->
		done(err, user)
		return
	return


#Setting Up Local Auth
passport.use new LocalStrategy (username, password, done) ->
	Character.findOne {username : username }, (err, user) ->
		console.log 'LOCAL', user
		if err
			return done(err)
		if !user
			return done(null, false, {message : 'Incorrect username'})
		if password isnt user.password
			return done(null, false, {message : 'Incorrect password'})
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


# # add this :  app.isAuthenticated,
# app.get '/:username', (req,res) ->
# 	db.User.find {username : req.param.username}, (err, data) ->
# 		console.log 'reqUser', req.param.username
# 		if err
# 			console.log 'error', err
# 		else
# 			console.log 'app', data
# 			res.render 'dash', {username : req.param.username}
# 	return

app.get '/dash', (req, res) ->
	res.render 'dash'

app.get '/login', (req, res) ->
	res.render 'login'
	return



#LOGIN/SIGNUP ROUTES

app.post '/signin', passport.authenticate('local'), (req, res) ->
	console.log 'req.user: ', req.user
	res.send {redirect : '/dash'}



app.post '/signup', (req, res) ->
	console.log 'reqBody', req.body
	newUser = new Character {
		email : req.body.email,
		password : req.body.password,
		username : req.body.username
	}
	newUser.save()
	console.log 'UserID', newUser._id
	res.send 'success!'
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



