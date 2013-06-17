require 'haml'
require 'json'
require 'sass'
require 'sinatra'
require 'sinatra/reloader'
require 'schema'

unless defined? SETTINGS
  SETTINGS = JSON.parse(open('settings.json').read)
end

if SETTINGS['sinatra_log']
  log_file = File.open(SETTINGS['sinatra_log'], 'a')

  $stdout.reopen(log_file)
  $stderr.reopen(log_file)
end

DB = Database('production.log')
DATES = Range.new(*[:min, :max].map {|x| Date.parse(Episode.send(x, :date))})

set :haml, {:format => :html5}
set :views, "#{File.dirname(__FILE__)}/view"
set :static_cache_control, [:public, {:max_age => 86400}]

helpers do
  include Rack::Utils

  alias_method :h, :escape_html

  # URI relative to root as defined in SETTINGS['root'].
  def r(s)
    t = SETTINGS['root']

    (s =~ /^\// && !(s =~ /^\/#{t}/)) ? "/#{t}#{s}" : s
  end

  def menu(exclude=false)
    (
     [['Home', '/'], ['Presenters', '/presenter/'], ['By year:']] +
     DATES.map {|x| x.year}.uniq.sort.reverse.map {|x| [x, "/#{x}/"]}
     ).
      reject {|x| exclude == x[1]}.
      map {|x, y| [x, y && r(y)]}
  end
end
