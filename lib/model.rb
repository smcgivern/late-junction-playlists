require 'sequel'

Sequel::Model.plugin(:schema)

def model_constant(s)
  Class.new.extend(Sequel::Inflections).instance_eval do
    constantize(singularize(camelize(s)))
  end
end

module Renameable
  def rename(new_name)
    klass = self.class
    existing = klass[:name => new_name]

    return update(:name => new_name) unless existing

    ds = playlist_tracks_dataset

    ds.update(ds.association_reflection[:key] => existing.id)
  end

  def swap(other)
    new_name = other.name

    other.rename(name)
    rename(new_name)
  end
end
