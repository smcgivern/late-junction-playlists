class Album < Sequel::Model
  include Renameable
  one_to_many :playlist_tracks, :eager => [:album, :artists, :composer,
                                           :episode, :track]

  set_schema do
    primary_key :id
    String :name, :size => 300
  end

  create_table?
end
