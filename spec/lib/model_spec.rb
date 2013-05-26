require './spec/setup'
require './lib/model'

DB = Sequel.sqlite

Dir['./model/*.rb'].each {|m| require m}

describe 'model_constant' do
  it 'should return the model class / constant from a table name' do
    class Foo < Sequel::Model; end

    model_constant(Foo.table_name).should.equal Foo
  end
end

describe 'Sequel::Model.rename' do
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

  it 'should return either itself, or the existing item' do
    baz = Track.create(:name => 'Baz')
    quux = Track.create(:name => 'Quux')
    foobar = Track.create(:name => 'Foobar')
    quux_id = quux.id
    foobar_id = foobar.id

    baz.add_playlist_track(:played => Time.now)

    baz.rename('Quux').id.should.equal quux_id
    foobar.rename('Bazquux').id.should.equal foobar_id
  end

  it 'should allow multiple renames' do
    foobar = Artist.create(:name => 'Foobar')
    barbaz = Artist.create(:name => 'Barbaz')
    bazquux = Artist.create(:name => 'Bazquux')

    foobar.add_playlist_track(:played => Time.now)

    foobar.rename('Barbaz').rename('Bazquux').name.should.equal 'Bazquux'
  end
end

describe 'Sequel::Model.swap' do
  it "should rename both items to each other's name" do
    foo = Composer.create(:name => 'Foo')
    bar = Track.create(:name => 'Bar')

    foo.swap(bar)

    Composer.where(:name => 'Foo').all.length.should.equal 0
    Composer.where(:name => 'Bar').all.length.should.equal 1
    Track.where(:name => 'Foo').all.length.should.equal 1
    Track.where(:name => 'Bar').all.length.should.equal 0
  end
end
