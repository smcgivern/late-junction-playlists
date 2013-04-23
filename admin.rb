require 'sinatra'
require 'sinatra/reloader'
require 'schema'

Database('admin.log')

set :views, 'view'

get '/' do
  haml :index
end

get '/episodes/all/' do
  @episodes = Episode.eager(:playlist_tracks, :presenter).all

  haml :episode_list
end

get '/episodes/missing-date/' do
  @episodes = Episode.
    where(:date => nil).
    eager(:playlist_tracks, :presenter).
    all

  haml :episode_list
end

get '/episodes/missing-playlist/' do
  @episodes = Episode.
    eager(:playlist_tracks, :presenter).
    all.
    select {|e| e.playlist_tracks.length == 0 }

  haml :episode_list
end

get '/episodes/missing-presenter/' do
  @episodes = Episode.
    where(:presenter => Presenter.where(Sequel.|({:name => nil},
                                                 {:name => ''}))).
    eager(:playlist_tracks, :presenter).
    all

  haml :episode_list
end

get '/episodes/:slug/' do
  @episode = Episode.by_slug(params['slug']).first

  haml :episode_page
end

get '/artists/contains-album/' do
  @artists = Artist.where(:name.like('%album%')).eager(:playlist_tracks).all

  haml :artist_list
end

get '/artists/:id/' do
  @artist = Artist[params['id'].to_i]

  haml :artist_page
end
