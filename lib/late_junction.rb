require 'date'
require 'open-uri'
require 'nokogiri'
require 'uri'

module LateJunction
  CACHE_DIRECTORY = 'tmp/playlists'

  PRESENTERS = ['Fiona Talkington', 'Verity Sharp', 'Max Reinhardt',
                'Nick Luscombe', 'Anne-Hilde Nesset']

  START_PAGES = {
    :legacy => 'http://www.bbc.co.uk/radio3/latejunction/pip/archive/',
    :current => 'http://www.bbc.co.uk/programmes/b006tp52/broadcasts',
  }

  def self.absolute(base)
    lambda {|x| URI.join(base, x['href']).to_s}
  end

  def self.cache_filename(uri)
    File.join(CACHE_DIRECTORY, uri.gsub(/\W/, '-'))
  end

  def self.html(uri)
    file = cache_filename(uri)
    to_open = File.exist?(file) ? file : uri
    page = Nokogiri::HTML(open(to_open))

    File.open(file, 'w').puts(page) unless File.exist?(file)

    page
  end

  def self.indices(source, uri=nil)
    uri ||= START_PAGES[source]
    page = html(uri)

    case source
    when :legacy
      return page.xpath('//a[starts-with(@href, "?")]').map(&absolute(uri)).uniq
    end
  end

  def self.episodes(source, uris=nil)
    uris ||= indices(source)

    uris.map do |uri|
      page = html(uri)

      page.css('div.month li a').map(&absolute(uri))
    end.flatten.uniq
  end

  def self.playlists(source, uris=nil)
    uris ||= episodes(source)

    uris.map do |uri|
      page = html(uri)
      playlist = {}

      date = DateTime.strptime(page.at('#broadcast_instance').inner_text,
                               '%A %d %B %Y %H:%M %z')

      playlist[:date] = date
      playlist[:title] = page.at('#episode-title').inner_text
      playlist[:description] = page.at('#episode-description').inner_text
      playlist[:presenter] = presenter(playlist[:description])
      playlist[:tracks] = tracks(page.at('#play-list').inner_text)
    end
  end

  def self.presenter(text)
    text.match(/(#{PRESENTERS.join('|')})/).to_s
  end

  def self.tracks(text)

  end
end
