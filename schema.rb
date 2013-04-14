require 'sequel'
require 'logger'

Sequel::Model.plugin(:schema)

def Database(log_file=nil, database_file='tmp/late_junction.db', level=:debug)
  log_to = (log_file ? "tmp/log/#{log_file}" : $stdout)

  Sequel.sqlite(database_file, :logger => Logger.new(log_to))

  Dir['model/*.rb'].each {|m| require m}
end
