class Presenter < Sequel::Model
  one_to_many :episodes

  set_schema do
    primary_key :id
    String :name
  end

  create_table?

  def slug
    name.downcase.gsub(/\W/, '-')
  end

  def self.by_slug(s)
    first { Sequel.ilike(:name, s.gsub(/\W/, ' ')) }
  end
end
