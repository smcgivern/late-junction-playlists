require 'haml'
require 'json'
require 'sass'
require 'sinatra'
require 'sinatra/reloader'
require 'schema'

DB = Database('admin.log')
LOGS = Hash[[:rename, :swap].map {|x| [x, Logger.new("tmp/log/#{x}.log")]}]

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
  @items = Artist.with_playlist_tracks(:name.ilike('%album%'))
  @page_title = 'Artists with album in their name'

  haml :item_list
end

get '/albums/contains-taken-from/' do
  @items = Album.with_playlist_tracks(:name.ilike('%taken from%'))
  @page_title = 'Albums with taken from in their name'

  haml :item_list
end

get '/albums/renameable/' do
  froms = [
           'album', 'compilation', 'EP', 'single', 'promo', 'sampler',
           'box set', 'opera', 'CD', 'sountrack', 'LP', 'OST',
           'promotional sampler', 'demo',
          ]

  @items = Album.with_playlist_tracks.select do |album|
    album.name =~ /\ATaken from the (#{froms.join('|')}):? /
  end

  @page_title = 'Albums that are automatically renameable'

  haml :item_list
end

get '/:type/all/' do
  @items = model_constant(params['type']).with_playlist_tracks
  @page_title = "All #{params['type']}"

  haml :item_list
end

get '/:type/:id/' do
  @item = model_constant(params['type'])[params['id'].to_i]
  @page_title = @item.name

  haml :item_page
end

post '/swap/' do
  a = model_constant(params['type_a'])[params['id_a'].to_i]
  b = model_constant(params['type_b'])[params['id_b'].to_i]

  LOGS[:swap].info ['Swap:',
                    JSON.generate([a.class, a.name.inspect, b.class,
                                   b.name.inspect])].join(' ')

  a.swap(b)

  redirect  "/#{a.class.table_name}/#{a.id}/"
end

post '/rename/' do
  original = model_constant(params['type'])[params['id'].to_i]

  LOGS[:rename].info ['Rename:',
                      JSON.generate([original.class, original.name.inspect,
                                     params['name']].inspect])].join(' ')

  renamed = original.rename(params['name'])

  redirect  "/#{renamed.class.table_name}/#{renamed.id}/"
end
