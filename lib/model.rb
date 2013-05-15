require 'sequel'

Sequel::Model.plugin(:schema)

def model_constant(s)
  Class.new.extend(Sequel::Inflections).instance_eval do
    constantize(singularize(camelize(s)))
  end
end

class Sequel::Model
  def rename(new_name)
    klass = self.class
    existing = klass[:name => new_name]

    if !existing
      update(:name => new_name)
    else
      playlist_tracks_dataset.update(klass.table_name.to_sym => existing[0].id)
    end
  end
end
