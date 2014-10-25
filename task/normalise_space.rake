desc 'Remove all extraneous spaces from item names'
task :normalise_space do
  require './schema'
  DB = Database('rake.log')

  [Artist, Album, Composer, Track].each do |klass|
    klass.all.each do |item|
      if item.name =~ /(\A | \Z|  )/
        puts "Removing space from #{klass} #{item.name.inspect} [#{item.id}]"

        item.rename(item.name.strip.gsub(/ +/, ' '))
      end
    end
  end
end
