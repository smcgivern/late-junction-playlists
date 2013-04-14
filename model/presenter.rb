class Presenter < Sequel::Model
  one_to_many :episodes

  set_schema do
    primary_key :id
    String :name
  end

  create_table?
end
