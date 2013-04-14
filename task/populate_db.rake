desc 'Populate database from JSON'
task :populate_db, :file do |t, args|
  require 'json'
  require 'schema'

  Database("#{args[:file].gsub(/\W/, '-')}-#{Time.now.strftime('%F-%T')}.log")

  JSON.parse(open(args[:file]).read).each do |ep|
    if ep.nil? || Episode.first(:uri => ep['uri'])
      puts "Skipping #{ep && ep['uri']}"

      next
    end

    puts "Processing #{ep['uri']}"

    presenter = Presenter.find_or_create(:name => ep['presenter'])
    episode = Episode.create(:presenter => presenter,
                             :uri => ep['uri'],
                             :date => ep['date'],
                             :name => ep['title'],
                             :description => ep['description'])

    ep['tracks'].each do |tr|
      next unless tr

      playlist_track = PlaylistTrack.create(:episode => episode)

      if episode.date and time = tr['time']
        if time > '10:00' and time < '12:00'
          time = "#{time.split(':')[0].to_i + 12}:#{time.split(':')[1]}"
        end

        date = episode.date + (time < '10:00' ? 1 : 0)

        begin
          playlist_track.played = "#{date}T#{time}:00Z"
        rescue
          puts "Invalid DateTime for track: #{tr.inspect}"
        end
      end

      playlist_track.track = Track.find_or_create(:name => tr['title'])
      playlist_track.composer = Composer.find_or_create(:name => tr['composer'])
      playlist_track.album = Album.find_or_create(:name => tr['album'])

      (tr['artists'] || []).each do |artist|
        playlist_track.add_artist(Artist.find_or_create(:name => artist))
      end

      playlist_track.save
    end
  end
end
