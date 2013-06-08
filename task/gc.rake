desc 'Remove all items which have no associations'
task :gc do
  require 'schema'
  DB = Database('rake.log')

  [Artist, Album, Composer, Track].each do |klass|
    klass.without_playlist_tracks.each do |item|
      puts "Deleting #{klass} #{item.name.inspect}"

      item.delete
    end
  end
end
