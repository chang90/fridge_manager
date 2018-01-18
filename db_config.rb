# require 'sinatra'
# require 'sinatra/reloader'
require 'active_record'

options = {
	adapter: 'postgresql',
	database: 'fridge_db',
	username: 'darkend'
}

# ActiveRecord::Base.establish_connection(options)
ActiveRecord::Base.establish_connection( ENV['DATABASE_URL'] || options)
