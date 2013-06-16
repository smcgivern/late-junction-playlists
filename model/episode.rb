class Episode < Sequel::Model
  many_to_one :presenter
  one_to_many :playlist_tracks, :eager => [:album, :artists, :composer, :track]

  set_schema do
    primary_key :id

    foreign_key :presenter_id, :presenters

    String :uri, :unique => true
    Date :date
    String :name
    String :description, :text => true
  end

  create_table?

  def title_date
    date.strftime('%e %B %Y').strip
  end

  def sorted_playlist_tracks
    key = playlist_tracks.all? {|x| x.played} ? :played : :id

    playlist_tracks.sort_by {|x| x.send(key)}
  end

  def slug
    uri.split('/').last
  end

  def self.by_slug(s)
    first { Sequel.like(:uri, "%/#{s}") }
  end
end
