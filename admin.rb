require 'haml'
require 'sass'
require 'sinatra'
require 'sinatra/reloader'
require 'schema'

DB = Database('admin.log')

set :views, 'view'

get '/style.css' do
  scss :style
end

get '/' do
  @page_title = 'Late Junction playlists'

  haml :index
end

get '/episodes/all/' do
  @episodes = Episode.eager(:playlist_tracks, :presenter).all
  @page_title = 'All episodes'

  haml :episode_list
end

get '/episodes/missing-date/' do
  @episodes = Episode.
    where(:date => nil).
    eager(:playlist_tracks, :presenter).
    all

  @page_title = 'Episodes missing dates'

  haml :episode_list
end

get '/episodes/missing-playlist/' do
  @episodes = Episode.
    eager(:playlist_tracks, :presenter).
    all.
    select {|e| e.playlist_tracks.length == 0 }

  @page_title = 'Episodes missing playlists'

  haml :episode_list
end

get '/episodes/missing-presenter/' do
  @episodes = Episode.
    where(:presenter => Presenter.where(Sequel.|({:name => nil},
                                                 {:name => ''}))).
    eager(:playlist_tracks, :presenter).
    all

  @page_title = 'Episodes missing presenters'

  haml :episode_list
end

get '/episodes/:slug/' do
  @episode = Episode.by_slug(params['slug']).first
  @page_title = @episode.date
  @page_link = @episode.uri

  haml :episode_page
end

get '/artists/all/' do
  @items = Artist.eager(:playlist_tracks).all
  @page_title = 'All artists'

  haml :item_list
end

get '/artists/contains-album/' do
  @items = Artist.where(:name.like('%album%')).eager(:playlist_tracks).all
  @page_title = 'Artists with album in their name'

  haml :item_list
end

get '/:type/:id/' do
  klass = model_const(params['type'])
  @item = klass[params['id'].to_i]
  @page_title = @item.name

  haml :item_page
end

def model_const(s)
  inf(:constantize, inf(:singularize, inf(:camelize, s)))
end

def inf(m, s)
  Class.new.extend(Sequel::Inflections).send(m, s)
end
