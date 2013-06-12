require 'haml'
require 'json'
require 'sass'
require 'sinatra'
require 'schema'

DB = Database('production.log')

set :views, 'view/'

get '/style.css' do
  scss :style
end

get '/' do
  @page_title = 'Late Junction playlists'

  haml :index
end
