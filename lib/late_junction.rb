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

  def self.html_to_text(html)
    Nokogiri::HTML(html.inner_html.gsub(/<\/?(br|p).*?>/, "\n")).inner_text
  end

  def self.indices(source, uri=nil)
    uri ||= START_PAGES[source]
    page = html(uri)

    case source
    when :legacy
      return page.xpath('//a[starts-with(@href, "?")]').map(&absolute(uri)).uniq
    when :current
      return page.css('.months li a').map(&absolute(uri)).uniq
    end
  end

  def self.episodes(source, uris=nil)
    uris ||= indices(source)

    uris.map do |uri|
      page = html(uri)

      case source
      when :legacy
        page.css('div.month li a')
      when :current
        page.css('#broadcast-items h4 a')
      end.map(&absolute(uri))
    end.flatten.uniq
  end

  def self.playlists(source, uris=nil)
    uris ||= episodes(source)

    uris.map do |uri|
      page = html(uri)
      playlist = {}

      case source
      when :legacy
        date = DateTime.strptime(page.at('#broadcast_instance').inner_text,
                                 '%A %d %B %Y %H:%M %z')

        playlist[:date] = date
        playlist[:title] = page.at('#episode-title').inner_text
        playlist[:description] = page.at('#episode-description').inner_text
        playlist[:presenter] = presenter(playlist[:description])
        playlist[:tracks] = tracks(html_to_text(page.at('#play-list')))
      end
    end
  end

  def self.presenter(text)
    text.match(/(#{PRESENTERS.join('|')})/).to_s
  end

  def self.tracks(text)
    parsed_tracks = []

    text.reduce([[]]) do |groups, line|
      stripped = line.gsub("\302\240", ' ').strip

      stripped.empty? ? groups << [] : groups.last << stripped
      groups
    end.reject do |x|
      x.empty?
    end.each do |group|
      next if group.length === 1

      # Fix lines that begin with a / by appending them to the previous line.
      group = group.reduce([]) {|g, l| (l[0..0] == '/' ? g.last : g) << l; g}

      titles, composer = group[1].split(/: */).reverse

      titles.split(/ *\/ */).each do |title|
        parsed_tracks << {
          :time => group[0].gsub('.', ':'),
          :composer => composer,
          :title => title,
          :artists => group[2].split(/ *\/ */),
          :album => group[3].gsub('Taken from the album ', ''),
        }
      end
    end

    parsed_tracks
  end
end
