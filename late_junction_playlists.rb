require 'setup'

get '/style.css' do
  scss :style
end

get '/' do
  @page_title = 'Late Junction playlists'
  @presenters = Presenter.all.select {|x| x.episodes.length > 0}

  haml :index
end
