require 'sequel'

Sequel::Model.plugin(:schema)

def model_constant(s)
  Class.new.extend(Sequel::Inflections).instance_eval do
    constantize(singularize(camelize(s)))
  end
end

module Renameable
  module InstanceMethods
    def rename(new_name)
      existing = self.class[:name => new_name]

      return update(:name => new_name) unless existing

      playlist_tracks.each do |pt|
        remove_playlist_track(pt)
        existing.add_playlist_track(pt)
      end

      existing
    end

    def swap(other)
      new_name = other.name

      other.rename(name)
      rename(new_name)
    end
  end

  def self.included base
    base.send :include, InstanceMethods
  end
end
