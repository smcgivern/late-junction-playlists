require 'sinatra'
require 'sinatra/reloader'
require 'schema'

Database('admin.log')

set :views, 'view'

get '/' do
  erb :index
end

get '/all-episodes/' do
  @episodes = Episode.all(:order => [:id.desc])

  erb :episode_list
end

get '/missing-date/' do
  @episodes = Episode.all(:date => nil, :order => [:id.desc])

  erb :episode_list
end

get '/missing-playlist/' do
  @episodes = Episode.all(:order => [:date.desc]).select do |episode|
    episode.playlist_tracks.length == 0
  end

  erb :episode_list
end

get '/missing-presenter/' do
  @episodes = Episode.all(Episode.presenter.name => nil, :order => [:id.desc])

  erb :episode_list
end

get '/:episode/' do
  @episode = Episode.get(params['episode'])

  erb :episode_page
end
