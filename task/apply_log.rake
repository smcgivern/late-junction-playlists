desc 'Apply admin modifications log to database'
task :apply_log, :file do |t, args|
  require './schema'
  DB = Database('rake.log')

  open(args[:file]).each do |line|
    next unless line.include?('INFO')

    x, type, data = *s.match(/\A.*?(Rename|Swap): (.*)\Z/)
    data = JSON.parse(data)

    case type
    when 'Rename'
      Object.const_get(data[0])[:name => data[1]].rename(data[2])
    when 'Swap'
      Object.const_get(data[0])[:name => data[1]].
        swap(Object.const_get(data[2])[:name => data[2]])
    when 'Edit date'
       Episode.by_slug(data[0]).
        update(:date => DateTime.strptime(data[1], '%Y-%m-%d'))
    when 'Edit presenter'
       Episode.by_slug(data[0]).
        update(:presenter => Presenter[:name => data[1]])
    end
  end
end
