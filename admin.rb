require 'sinatra'
require 'sinatra/reloader'
require 'schema'

Database('admin.log')

set :views, 'view'

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

get '/artists/contains-album/' do
  @artists = Artist.where(:name.like('%album%')).eager(:playlist_tracks).all
  @page_title = 'Artists with album in their name'

  haml :artist_list
end

get '/:type/:id/' do
  klass = Kernel.const_get(params['type'][0...-1].sub(/./) {|x| x.upcase})
  @item = klass[params['id'].to_i]
  @page_title = @item.name

  haml :item_page
end
