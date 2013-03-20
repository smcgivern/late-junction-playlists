Dir['*.rake'].each {|t| load(t)}

desc 'Run all specs in spec/'
task :spec do
  require 'bacon'

  Bacon.extend Bacon::TestUnitOutput
  Bacon.summary_on_exit

  Dir['spec/**/*.rb'].each {|f| require "./#{f}"}
end

desc 'Pull all playlists from source, leaving info as JSON in tmp/'
task :playlists, :source do |t, args|
  require 'lib/late_junction'
  require 'json'

  args.with_defaults(:source => 'legacy')

  open("tmp/#{args[:source]}-#{Time.now.strftime('%F-%T')}.json", 'w').
    puts(JSON.pretty_generate(LateJunction.playlists(args[:source].to_sym)))
end
