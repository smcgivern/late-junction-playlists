require 'date'
require 'open-uri'
require 'nokogiri'
require 'uri'

module LateJunction
  CACHE_DIRECTORY = 'tmp/playlists'

  PRESENTERS = ['Fiona Talkington', 'Verity Sharp', 'Max Reinhardt',
                'Nick Luscombe', 'Anne Hilde Neset', 'Robert Sandall',
                'Shaheera Asante', 'Mark Russell', 'Mara Carlyle']

  START_PAGES = {
    :legacy => 'http://www.bbc.co.uk/radio3/latejunction/pip/archive/',
    :current => 'http://www.bbc.co.uk/programmes/b006tp52/broadcasts',
  }

  def self.add_time(a, b)
    h, m, i, n = *"#{a}:#{b}".split(':').map {|x| x.to_i}
    x = h + i
    y = m + n

    if y >= 60
      x += 1
      y -= 60
    end

    x -= 24 if x >= 24

    "%02d:%02d" % [x, y]
  end

  def self.absolute(base)
    lambda {|x| URI.join(base, x['href']).to_s}
  end

  def self.cache_filename(uri)
    File.join(CACHE_DIRECTORY, uri.gsub(/\W/, '-'))
  end

  def self.uncache(uri)
    File.unlink(cache_filename(uri))
  end

  def self.html(uri, force=false)
    file = cache_filename(uri)
    use_cache = (File.exists?(file) && !force)
    to_open = use_cache ? file : uri
    page = open(to_open).read

    unless use_cache
      FileUtils.mkdir_p(CACHE_DIRECTORY) unless File.exists?(CACHE_DIRECTORY)

      cached = open(file, 'w')

      cached.puts(page)
      cached.flush
    end

    Nokogiri::HTML(page)
  end

  def self.html_to_text(html, encoding='utf-8')
    return '' unless html

    line_breaks = /<\/?(br|p|div|h[1-6]).*?>/

    Nokogiri::HTML(html.inner_html.force_encoding(encoding).gsub(line_breaks, "\n")).inner_text
  end

  def self.inner_text(root)
    lambda {|s| (e = root.at(s)) ? e.inner_text : nil}
  end

  def self.indices(source, uri=nil, force=nil)
    uri ||= START_PAGES[source]
    page = html(uri, force)

    case source
    when :legacy
      return page.xpath('//a[starts-with(@href, "?")]').map(&absolute(uri)).uniq
    when :current
      return page.css('.months li a').map(&absolute(uri)).uniq
    end
  end

  def self.episodes(source, uris=nil, force=nil)
    uris ||= indices(source, nil, force)

    uris.map do |uri|
      page = html(uri, force)

      case source
      when :legacy
        page.css('div.month li a')
      when :current
        page.css('#broadcast-items h4 a')
      end.map(&absolute(uri))
    end.flatten.uniq
  end

  def self.playlists(source, uris=nil, force=nil)
    uris ||= episodes(source, nil, force)

    uris.map do |uri|
      page = html(uri, force)
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

        playlist[:tracks] = tracks(source, html_to_text(page.at('#play-list'), 'iso-8859-1'))
      when :current
        unless (date_text = (page.at('#last-on .details, .broadcast-event__time'))) &&
               date_text['content']

          self.uncache(uri)

          next
        end

        playlist[:date] = DateTime.strptime(date_text['content'], '%Y-%m-%d')

        if playlist[:date] > DateTime.now
          self.uncache(uri)

          next
        end

        playlist[:title] = text['h1.episode-title, h1[property=name]']
        playlist[:presenter] = presenter(playlist[:title])

        if playlist[:presenter].empty?
          playlist[:presenter] = presenter(text['#synopsis, .ml__content.prose'])
        end

        if lazy = page.at('.lazy-module')
          segments = html(URI.join(uri, lazy['data-lazyload-inc']).to_s)
        end

        if (segments ||= page.at('#segments'))
          start_time = date_text['content'].match(/\d\d:\d\d/)[0]
          playlist[:description] = text['#synopsis, .ml__content.prose']
          playlist[:tracks] = structured_tracks(segments, start_time)
        else
          playlist[:description] = text['#episode-summary']
          playlist[:tracks] = tracks(source,
                                     page.at('#synopsis .copy')['content'])
        end

        if playlist[:tracks].empty? || !playlist[:presenter]
          self.uncache(uri)

          next
        end
      end

      playlist
    end
  end

  def self.presenter(text)
    text && text.match(/(#{PRESENTERS.join('|')})/).to_s
  end

  def self.tracks(source, text, time=nil)
    parsed_tracks = []

    text.split("\n").reduce([[]]) do |groups, line|
      stripped = line.gsub("\302\240", ' ').strip

      stripped.empty? ? groups << [] : groups.last << stripped
      groups
    end.reject do |x|
      x.empty?
    end.each_with_index do |group, i|
      next if (group.length < 3 or group[0] == 'LATE JUNCTION')

      if time
        group.unshift((time + (i * 180)).strftime('%H:%M'))
      elsif !group[0].match(/[0-9][0-9]\W[0-9][0-9]/)
        next
      end

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

  def self.structured_tracks(segments, start_time)
    segments.css('li.segment.track, .segment__track').map do |segment|
      text = inner_text(segment)
      play_time = text['.play-time, .text--subtle.pull--right-spaced']

      next unless (artists = text['.artist'])

      album = text['.release-title, .inline em']

      {
        :time => play_time && add_time(start_time, play_time),
        :artists => artists.split(/ *\/ */),
        :title => text['.title, p[property=name]'],
        :album => album && album.gsub(/\W+$/, ''),
      }
    end
  end
end
