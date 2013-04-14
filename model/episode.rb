class Episode < Sequel::Model
  many_to_one :presenter
  one_to_many :playlist_tracks

  set_schema do
    primary_key :id

    foreign_key :presenter_id, :presenters

    String :uri, :unique => true
    Date :date
    String :name
    String :description, :text => true
  end

  create_table?
end
