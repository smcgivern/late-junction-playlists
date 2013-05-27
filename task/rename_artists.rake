desc "Rename artists that start with 'taken from'"
task :rename_artists do
  require 'schema'
  DB = Database('rake.log')

  froms = [
           'album', 'compilation', 'EP', 'single', 'promo', 'sampler',
           'box set', 'opera', 'CD', 'sountrack', 'LP', 'OST',
           'promotional sampler', 'demo',
          ]

  re = /\ATaken from the (#{froms.join('|')}):? /i

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
