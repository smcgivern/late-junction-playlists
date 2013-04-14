class PlaylistTrack < Sequel::Model
  many_to_one :episode
  many_to_one :track
  many_to_one :composer
  many_to_one :album
  many_to_many :artists

  set_schema do
    primary_key :id

    foreign_key :episode_id, :episodes
    foreign_key :track_id, :tracks
    foreign_key :composer_id, :composers
    foreign_key :album_id, :albums

    DateTime :played
  end

  create_table?
end
