desc "Rename artists and / or albums that start with 'taken from'"
task :rename, :type do |t, args|
  require 'schema'
  DB = Database('rake.log')

  args.with_defaults(:type => :both)

  rename((args[:type] || :both).to_sym)
end

def rename(type)
  froms = [
           'album', 'compilation', 'EP', 'single', 'promo', 'sampler',
           'box set', 'opera', 'CD', 'sountrack', 'LP', 'OST',
           'promotional sampler', 'demo',
          ]

  re = /\ATaken from the (#{froms.join('|')}):? /i

  case type
  when :both
    rename(:albums)
    rename(:artists)

  when :albums
    Album.with_playlist_tracks.each do |album|
      if album.name =~ re
        puts "Renaming #{album.name}"

        album.rename(album.name.gsub(re, ''))
      end
    end

  when :artists
    Artist.with_playlist_tracks.each do |artist|
      next unless artist.name =~ re

      artist_name = artist.name.gsub(re, '')
      playlist_track = artist.playlist_tracks.first
      album, composer = *[:album, :composer].map {|x| playlist_track.send(x)}

      puts "Renaming #{[artist, album, composer].map {|x| x.name}.inspect}"

      artist.rename(composer ? composer.name : artist_name)
      composer.rename(nil)
      album.rename(artist_name)
    end
  end
end
