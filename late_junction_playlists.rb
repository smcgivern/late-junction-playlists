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

get %r{/(album|artist|composer|track)/(\d+)/} do
  @type, id = *params[:captures]
  @item = model_constant(@type)[id.to_i]
  @page_title = @item.name

  haml :item
end

# Day (not linked; redirects to day's episode if there is one, otherwise month).
get %r{/(20\d\d)/([01]\d)/([0123]\d)/} do
  year, month, day = *params[:captures].map {|x| x.to_i}
  episode = Episode[:date => Date.new(year, month, day)]

  redirect r(episode ? "/episode/#{episode.slug}/" : "/#{year}/#{month}/")
end

# Month (shows calendar for single month).
get %r{/(20\d\d)/([01]\d)/} do
  year, month = *params[:captures].map {|x| x.to_i}
  @range = Date.new(year, month)..Date.new(year, month, -1)
  @episodes = Episode.where(:date => @range).to_hash(:date)
  @page_title = "Late Junction episodes for #{@range.first.strftime('%B %Y')}"

  redirect r("/#{year}/") if @episodes.empty?

  haml :month
end

# Year (shows mini-calendar for all 12 months.
get %r{/(20\d\d)/} do
  year = *params[:captures].map {|x| x.to_i}
  @range = Date.new(year)..Date.new(year, -1, -1)
  @episodes = Episode.where(:date => @range).to_hash(:date)
  @page_title = "Late Junction episodes for #{year}"

  haml :year
end
