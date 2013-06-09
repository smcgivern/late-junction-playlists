desc 'Dump playlist text for episodes missing playlists'
task :missing_playlists do
  require 'schema'
  require 'lib/late_junction'

  DB = Database('rake.log')
  dir = "tmp/manual/#{Time.now.strftime('%F-%T')}"

  mkdir_p(dir)

  Episode.
    eager(:playlist_tracks, :presenter).
    all.
    select {|e| e.playlist_tracks.length == 0 }.
    each do |episode|

    episode_page = LateJunction.html(episode.uri)
    filename = "#{dir}/#{episode.slug}"

    begin
      (text = LateJunction.html_to_text(episode_page.at('#play-list'))).empty? &&
        (text = episode_page.at('#synopsis .copy')['content'])


      puts "Writing #{filename}"
      open(filename, 'w').puts(text)
    rescue
      puts "Error with #{episode.uri}"
    end
  end
end

desc 'Parse playlists that have been manually tidied and placed in dir'
task :parse_manual_playlists, :dir do |t, args|
  require 'lib/late_junction'
  require 'json'

  output = "tmp/manual-#{Time.now.strftime('%F-%T')}.json"

  playlists = Dir["#{args[:dir]}/*"].map do |filename|

    file = open(filename).read
    slug = filename.split('/').last
    time = (file =~ /\A[0-9]/ ? nil : Time.utc(2000, 1, 1, 22, 45))

    {:uri => slug, :tracks => LateJunction.tracks(:legacy, file, time)}
  end

  open(output, 'w').puts(JSON.pretty_generate(playlists))

  puts output
end
