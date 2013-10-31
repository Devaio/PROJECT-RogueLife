# passport = require 'passport'
# LocalStrategy = require("passport-local").Strategy
# mongoose = require 'mongoose'
# express = require 'express' 
# app = express();
# module.exports = (passport, LocalStrategy, mongoose) ->


# 	### MONGO ####

# 	MongoURI = process.env.MONGOLAB_URI ? 'mongodb://localhost/roguelife'
# 	mongoose.connect MongoURI

# 	#Setting Up Local Auth
# 	passport.use new LocalStrategy (username, password, done) ->
# 		User.findOne {username : username }, (err, user) ->
# 			if err
# 				console.log 'err', err
# 				return done(err)
# 			if !user
# 				console.log '!user', user
# 				return done(null, false)
# 			if user.password isnt password
# 				console.log 'pass', user.password, password
# 				return done(null, false)
# 			return
# 		return
# 	#Ensure User is Authenticated
# 	app.isAuthenticated = (request, response, next) ->
# 	    if request.isAuthenticated()
# 	        return next()
# 	    response.redirect "/login"
# 	    return

# 	ensureAuthenticated = (req, res, next) ->
# 		if req.isAuthenticated()
# 			return next
# 		res.redirect('/login')
# 		return

# 	#Passport needs to serialize to support persistent login sessions
# 	passport.serializeUser (user, done) ->
# 		done null, user.id
# 		return

# 	passport.deserializeUser (id, done) ->
# 		User.findById id, (err, user) ->
# 			done(err, user)
# 			return
# 		return
# 	# #Setting Up OpenID for Steam Auth
# 	# passport.use new SteamStrategy {
# 	# 	returnURL: 'http://'+process.env.domain+'/auth/steam/return', 
# 	# 	realm: 'http://'+process.env.domain+'/' 
# 	# 	},(identifier, done) ->
# 	# 		User.findByOpenID { openId: identifier }, (err, user) ->
# 	# 		return done(err, user);

# 	return