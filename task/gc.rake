desc 'Remove all items which have no associations'
task :gc do
  require 'schema'
  DB = Database('rake.log')

  DB[Episode.table_name].
    to_hash_groups(:date, :id).
    select {|k, v| v.length > 1}.
    map {|x| [x[0], x[1].map {|z| Episode[z]}]}.
    each do |date, episodes|

    next if episodes.map {|x| x.playlist_tracks.length}.max == 0

    episodes.each do |episode|
      if (episode.playlist_tracks.length == 0 ||
          episodes.map {|x| x.id}.max > episode.id)

        puts "Deleting episode #{episode.id} for #{date}"

        episode.playlist_tracks.each do |playlist_track|
          playlist_track.remove_all_artists
          playlist_track.destroy
        end

        episode.destroy
      end
    end
  end

  [Artist, Album, Composer, Track].each do |klass|
    klass.without_playlist_tracks.each do |item|
      puts "Deleting #{klass} #{item.name.inspect}"

      item.destroy
    end
  end
end
