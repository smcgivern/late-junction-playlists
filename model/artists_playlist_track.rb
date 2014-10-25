require './model/artist'
require './model/playlist_track'

class ArtistsPlaylistTrack < Sequel::Model
  set_schema do
    primary_key :id

    foreign_key :artist_id, :artists
    foreign_key :playlist_track_id, :playlist_tracks

    DateTime :played
  end

  create_table?
end
