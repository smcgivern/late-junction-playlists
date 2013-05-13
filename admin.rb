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
  @title_link = @episode.uri

  haml :episode_page
end

get '/artists/contains-album/' do
  @items = Artist.where(:name.ilike('%album%')).eager(:playlist_tracks).all
  @page_title = 'Artists with album in their name'

  haml :item_list
end

get '/albums/contains-taken-from/' do
  @items = Album.where(:name.ilike('%taken from%')).eager(:playlist_tracks).all
  @page_title = 'Albums with taken from in their name'

  haml :item_list
end

get '/albums/renameable/' do
  froms = [
           'album', 'compilation', 'EP', 'single', 'promo', 'sampler',
           'box set', 'opera', 'CD', 'sountrack', 'LP', 'OST',
           'promotional sampler', 'demo',
          ]

  @items = Album.eager(:playlist_tracks).all.select do |album|
    album.name =~ /\ATaken from the (#{froms.join('|')}):? /
  end

  @page_title = 'Albums that are automatically renameable'

  haml :item_list
end

get '/:type/all/' do
  @items = model_constant(params['type']).eager(:playlist_tracks).all
  @page_title = "All #{params['type']}"

  haml :item_list
end

get '/:type/:id/' do
  @item = model_constant(params['type'])[params['id'].to_i]
  @page_title = @item.name

  haml :item_page
end
