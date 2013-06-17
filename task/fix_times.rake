desc 'Fix playlist tracks with times that should be from episode start'
task :fix_times => [:backup_db] do
  require 'lib/late_junction'
  require 'schema'

  DB = Database('rake.log')

  Episode.all.select {|x| x.slug.length == 8}.each do |episode|
    page = LateJunction.html(episode.uri)

    next unless page.at('#segments')

    start_time = page.at('#last-on .details')['content'].match(/\d\d:\d\d/)[0]

    puts "Fixing times for #{episode.date}"

    episode.playlist_tracks.each do |pt|
      if (played = pt.played)
        time = LateJunction.add_time(start_time, played.utc.strftime('%H:%M'))
        date = episode.date + (time < '10:00' ? 1 : 0)

        pt.update(:played => "#{date}T#{time}:00Z")
      end
    end
  end
end
