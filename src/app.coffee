

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
db = require './db'
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

MongoURI = process.env.MONGOLAB_URI ? 'mongodb://localhost/roguelife'
mongoose.connect MongoURI


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
#Ensure User is Authenticated
app.isAuthenticated = (request, response, next) ->
    if request.isAuthenticated()
        return next()
    response.redirect "/login"
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
	User.findById id, (err, user) ->
		done(err, user)
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
	# db.User.find {_id : req.user._id}
	res.send '/'
	return



app.post '/signup', (req, res) ->
	console.log 'reqBody', req.body
	user = new db.User {
		email : req.body.email,
		password : req.body.password,
		username : req.body.username
	}
	console.log 'UserID', user._id
	user.save (err) ->
		if err
			res.send err
		else
			User.findById user['_id'], (err, userData) ->
				res.render '/'+username, {user : userData}
				return
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



