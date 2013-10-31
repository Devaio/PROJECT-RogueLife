mongoose = require 'mongoose'

User = mongoose.model 'User', {
    username : {type : String, required : true, unique : true},
    email : {type: String, required : true, unique : true},
    password : {type : String, required : true},
    health : {type : Number, default : 100},
    mana : {type : Number, default : 50},
    experience : {type : Number, default : 0},
    tasks : {type: Array, default : []}
}

exports.User = User