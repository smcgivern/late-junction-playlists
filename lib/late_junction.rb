require 'date'
require 'open-uri'
require 'nokogiri'
require 'uri'

module LateJunction
  CACHE_DIRECTORY = 'tmp/playlists'

  PRESENTERS = ['Fiona Talkington', 'Verity Sharp', 'Max Reinhardt',
                'Nick Luscombe', 'Anne-Hilde Neset']

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
    return '' unless html

    line_breaks = /<\/?(br|p|div|h[1-6]).*?>/

    Nokogiri::HTML(html.inner_html.gsub(line_breaks, "\n")).inner_text
  end

  def self.inner_text(root)
    lambda {|s| (e = root.at(s)) ? e.inner_text : nil}
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
      playlist = {:uri => uri}
      text = inner_text(page)

      case source
      when :legacy
        if (date_text = text['#broadcast-instance'])
          playlist[:date] = DateTime.strptime(date_text, '%A %d %B %Y')
          playlist[:title] = text['#episode-title']
          playlist[:description] = text['#episode-description']
          playlist[:presenter] = presenter(playlist[:description])
        end

        playlist[:tracks] = tracks(source, html_to_text(page.at('#play-list')))
      when :current
        next unless (date_text = page.at('#last-on .details'))

        playlist[:date] = DateTime.strptime(date_text['content'], '%Y-%m-%d')

        playlist[:title] = text['h1.episode-title']
        playlist[:presenter] = presenter(playlist[:title])

        if (segments = page.at('#segments'))
          playlist[:description] = text['#synopsis']
          playlist[:tracks] = structured_tracks(segments)
        else
          playlist[:description] = text['#episode-summary']
          playlist[:tracks] = tracks(source,
                                     page.at('#synopsis .copy')['content'])
        end
      end

      playlist
    end
  end

  def self.presenter(text)
    text.match(/(#{PRESENTERS.join('|')})/).to_s
  end

  def self.tracks(source, text)
    parsed_tracks = []

    text.reduce([[]]) do |groups, line|
      stripped = line.gsub("\302\240", ' ').strip

      stripped.empty? ? groups << [] : groups.last << stripped
      groups
    end.reject do |x|
      x.empty?
    end.each do |group|
      next if (group.length < 3 or
               group[0] == 'LATE JUNCTION' or
               !group[0].match(/[0-9][0-9]\W[0-9][0-9]/))

      # Fix lines that begin with a / by appending them to the previous line.
      group = group.reduce([]) {|g, l| (l[0..0] == '/' ? g.last : g) << l; g}

      titles, composer = group[1].split(/: */).reverse

      titles.split(/ *\/ */).each do |title|
        parsed_track = {
          :time => group[0].gsub('.', ':'),
          :title => title,
        }

        case source
        when :legacy
          next unless group[3]

          parsed_track[:composer] = composer
          parsed_track[:artists] = group[2].split(/ *\/ */)
          parsed_track[:album] = group[3].gsub('Taken from the album ', '')
        when :current
          if group[2].include?('Album: ')
            parsed_track[:artists] = composer.split(/ *\/ */) if composer
            parsed_track[:album] = group[2].gsub('Album: ', '')
          else
            parsed_track[:composer] = composer
            parsed_track[:artists] = group[2].split(/ *\/ */)
            parsed_track[:album] = group[3].gsub('Album: ', '') if group[3]
          end
        end

        parsed_tracks << parsed_track
      end
    end

    parsed_tracks
  end

  def self.structured_tracks(segments)
    segments.css('li.segment.track').map do |segment|
      text = inner_text(segment)

      next unless (artists = text['.artist'])

      {
        :time => text['.play-time'],
        :artists => artists.split(/ *\/ */),
        :title => text['.title'],
        :album => text['.release-title'],
      }
    end
  end
end
