require 'haml'
require 'json'
require 'sass'
require 'sinatra'
require 'sinatra/reloader'
require 'schema'

unless defined? SETTINGS
  SETTINGS = JSON.parse(open('settings.json').read)
end

if SETTINGS['sinatra_log']
  log_file = File.open(SETTINGS['sinatra_log'], 'a')

  $stdout.reopen(log_file)
  $stderr.reopen(log_file)
end

DB = Database('production.log')

set :haml, {:format => :html5}
set :views, "#{File.dirname(__FILE__)}/view"
set :static_cache_control, [:public, {:max_age => 86400}]
