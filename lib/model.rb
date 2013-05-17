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
      ds = playlist_tracks_dataset

      ds.update(ds.association_reflection[:key] => existing.id)
    end
  end
end
