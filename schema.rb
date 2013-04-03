require 'data_mapper'

DataMapper.setup(:default, "sqlite://#{Dir.pwd}/tmp/late_junction.db")

class Presenter
  include DataMapper::Resource

  has n, :episodes, :through => Resource

  property :id, Serial
  property :name, String, :length => 500
end

class Track
  include DataMapper::Resource

  has n, :playlist_tracks, :through => Resource

  property :id, Serial
  property :name, String, :length => 500
end

class Artist
  include DataMapper::Resource

  has n, :playlist_tracks, :through => Resource

  property :id, Serial
  property :name, String, :length => 500
end

class Composer
  include DataMapper::Resource

  has n, :playlist_tracks, :through => Resource

  property :id, Serial
  property :name, String, :length => 500
end

class Album
  include DataMapper::Resource

  has n, :playlist_tracks, :through => Resource

  property :id, Serial
  property :name, String, :length => 500
end

class PlaylistTrack
  include DataMapper::Resource

  belongs_to :episode
  has 1, :track, :through => Resource
  has n, :artists, :through => Resource
  has 1, :composer, :through => Resource
  has 1, :album, :through => Resource

  property :id, Serial
  property :played, DateTime
end

class Episode
  include DataMapper::Resource

  has 1, :presenter, :through => Resource
  has n, :playlist_tracks

  property :id, Serial
  property :uri, String, :unique => true
  property :date, Date
  property :name, String, :length => 500
  property :description, Text
end

DataMapper.finalize
DataMapper.auto_upgrade!
