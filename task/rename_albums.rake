desc "Rename albums that start with 'taken from'"
task :rename_albums do
  require 'schema'
  DB = Database('rake.log')

  froms = [
           'album', 'compilation', 'EP', 'single', 'promo', 'sampler',
           'box set', 'opera', 'CD', 'sountrack', 'LP', 'OST',
           'promotional sampler', 'demo',
          ]

  re = /\ATaken from the (#{froms.join('|')}):? /

  Album.all.each do |album|
    album.rename(album.name.gsub(re, '')) if album.name =~ re
  end
end
