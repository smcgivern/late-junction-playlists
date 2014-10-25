desc 'Pull all playlists from source, leaving info as JSON in tmp/'
task :playlists, :source, :since do |t, args|
  require './lib/late_junction'
  require 'json'

  args.with_defaults(:source => 'legacy', :since => '')

  filename = "tmp/#{args[:source]}-#{Time.now.strftime('%F-%T')}.json"
  playlists = LateJunction.playlists(args[:source].to_sym).
    select {|x| x && x[:date].to_s >= args[:since]}

  file = open(filename, 'w')

  file.puts(JSON.pretty_generate(playlists))
  file.flush
  file.close

  puts filename
end

desc 'Get new playlists (current only) since last update'
task :new_playlists do
  require './lib/late_junction'

  LateJunction.episodes(:current, nil, :force)
  Rake::Task[:playlists].invoke(:current, '2012')
end

desc 'Update DB using the new playlists'
task :update => [:backup_db, :new_playlists] do
  Rake::Task[:populate_db].invoke(Dir['tmp/current-*.json'].sort.last)
end
