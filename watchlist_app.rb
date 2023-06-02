require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"
require "bcrypt"

require_relative "media"
require_relative "watchlist"
require_relative "database_persistence"