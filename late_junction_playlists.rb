require 'setup'

get '/ext/style.css' do
  scss :style
end

get '/' do
  year, month = *[:year, :month].map {|x| DATES.max.send(x)}
  @range = Date.new(year, month)..Date.new(year, month, -1)
  @episodes = Episode.where(:date => @range).to_hash(:date)
  @page_title = 'Late Junction playlists'
  @menu = menu('/')

  haml :index
end

get '/episode/:slug/' do
  @episode = Episode.by_slug(params['slug'])
  @page_title = [[@episode.title_date, @episode.uri,
                  'Original page for this playlist'],
                 '&#8211;',
                 [@episode.presenter.name, "/presenter/#{@episode.presenter.slug}/"]]

  haml :episode
end

get '/presenter/' do
  @presenters = Presenter.eager(:episodes).all.sort_by {|x| -x.episodes.length}
  @page_title = 'Late Junction presenters'
  @menu = menu('/presenter/')

  haml :presenter_list
end

get '/presenter/:slug/' do
  @presenter = Presenter.by_slug(params['slug'])
  @episodes = Episode.where(:presenter => @presenter).to_hash(:date)
  min, max = *[:min, :max].map {|x| @episodes.keys.send(x)}
  @range = Date.new(min.year, min.month)..Date.new(max.year, max.month, -1)
  @page_title = "Late Junction episodes presented by #{@presenter.name}"

  haml :presenter
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
  @menu = menu("/#{year}/")

  haml :year
end

get %r{/(album|artist|composer|episode|track)/} do
  redirect r('/')
end
