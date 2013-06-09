desc 'Pull all playlists from source, leaving info as JSON in tmp/'
task :playlists, :source do |t, args|
  require 'lib/late_junction'
  require 'json'

  args.with_defaults(:source => 'legacy')

  filename = "tmp/#{args[:source]}-#{Time.now.strftime('%F-%T')}.json"

  open(filename, 'w').
    puts(JSON.pretty_generate(LateJunction.playlists(args[:source].to_sym)))

  puts filename
end

desc 'Get new playlists (current only) since last update'
task :new_playlists do
  require 'lib/late_junction'

  LateJunction.episodes(:current, nil, :force)
  Rake::Task[:playlists].invoke(:current)
end
