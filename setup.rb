require 'haml'
require 'json'
require 'sass'
require 'sinatra'
require 'sinatra/reloader'
require 'schema'

DB = Database('production.log')

set :haml, {:format => :html5}
set :views, "#{File.dirname(__FILE__)}/view"
set :static_cache_control, [:public, {:max_age => 86400}]
