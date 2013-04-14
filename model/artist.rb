class Artist < Sequel::Model
  many_to_many :playlist_tracks

  set_schema do
    primary_key :id
    String :name
  end

  create_table?
end
