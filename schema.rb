require 'sequel'
require 'logger'

Sequel::Model.plugin(:schema)

def Database(log_file=nil, database_file='tmp/late_junction.db', level=:debug)
  log_to = (log_file ? "tmp/log/#{log_file}" : $stdout)

  FileUtils.mkdir_p('tmp/log') unless File.exists?('tmp/log')

  db = Sequel.sqlite(database_file, :logger => Logger.new(log_to))

  Dir['model/*.rb'].each {|m| require m}

  db
end

def model_constant(s)
  Class.new.extend(Sequel::Inflections).instance_eval do
    constantize(singularize(camelize(s)))
  end
end

class Sequel::Model
  def rename(new_name)
    klass = self.class
    existing = klass.where(:name => new_name).all

    if existing.empty?
      update(:name => new_name)
    else
      playlist_tracks_dataset.update(klass.table_name.to_sym => existing[0].id)
    end
  end
end
