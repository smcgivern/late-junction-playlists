require 'sinatra'
require 'sinatra/reloader'
require 'schema'

set :views, 'view'

get '/' do
  @episodes = Episode.all(:order => [:date.desc])

  erb :episode_list
end

get '/:episode/' do
  @episode = Episode.get(params['episode'])

  erb :episode_page
end
