require 'setup'

get '/ext/style.css' do
  scss :style
end

get '/' do
  @page_title = 'Late Junction playlists'
  @presenters = Presenter.all.select {|x| x.episodes.length > 0}

  haml :index
end

get '/episode/' do
  redirect r('/')
end

get '/episode/:slug/' do
  @episode = Episode.by_slug(params['slug'])
  @page_title = "#{@episode.title_date} - #{@episode.presenter.name}"

  haml :episode
end

get '/presenter/' do
  @presenters = Presenter.eager(:episodes).all.sort_by {|x| -x.episodes.length}
  @page_title = 'Late Junction presenters'

  haml :presenter_list
end
