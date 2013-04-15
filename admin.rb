require 'sinatra'
require 'sinatra/reloader'
require 'schema'

Database('admin.log')

set :views, 'view'

get '/' do
  haml :index
end

get '/all-episodes/' do
  @episodes = Episode.eager(:playlist_tracks, :presenter).all

  haml :episode_list
end

get '/missing-date/' do
  @episodes = Episode.where(:date => nil).eager(:playlist_tracks, :presenter).all

  haml :episode_list
end

get '/missing-playlist/' do
  @episodes = Episode.
    eager(:playlist_tracks, :presenter).
    all.
    select {|e| e.playlist_tracks.length == 0 }

  haml :episode_list
end

get '/missing-presenter/' do
  @episodes = Episode.
    where(:presenter => Presenter.where(Sequel.|({:name => nil},
                                                 {:name => ''}))).
    eager(:playlist_tracks, :presenter).
    all

  haml :episode_list
end

get '/:episode/' do
  @episode = Episode.get(params['episode'])

  haml :episode_page
end
