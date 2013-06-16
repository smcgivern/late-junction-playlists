class Composer < Sequel::Model
  include Renameable
  one_to_many :playlist_tracks, :eager => [:album, :artists, :composer,
                                           :episode, :track]

  set_schema do
    primary_key :id
    String :name
  end

  create_table?
end
