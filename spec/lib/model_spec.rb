require './spec/setup'
require './lib/model'

DB = Sequel.sqlite

describe 'model_constant' do
  it 'should return the model class / constant from a table name' do
    class Foo < Sequel::Model; end

    model_constant(Foo.table_name).should.equal Foo
  end
end

describe 'Sequel::Model.rename' do
  before do
    Dir['model/*.rb'].each {|m| require m}
  end

  it 'should rename the item directly if none exists with the new name' do
    Artist.create(:name => 'Foo').rename('Bar')

    Artist.where(:name => 'Foo').all.length.should.equal 0
    Artist.where(:name => 'Bar').all.length.should.equal 1
  end

  it 'should reassign to the existing item otherwise' do
    baz = Album.create(:name => 'Baz')
    quux = Album.create(:name => 'Quux')

    baz.add_playlist_track(:played => Time.now)
    baz.rename('Quux')

    baz.playlist_tracks.length.should.equal 0
    quux.playlist_tracks.length.should.equal 1
  end
end
