class Album < Sequel::Model
  one_to_many :playlist_tracks

  set_schema do
    primary_key :id
    String :name, :size => 300
  end

  create_table?
end
