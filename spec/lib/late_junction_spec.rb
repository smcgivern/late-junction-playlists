require './spec/setup'
require './lib/late_junction'

require 'tmpdir'

describe 'LateJunction.absolute' do
  it 'should return a block for converting the href to an absolute URI' do
    absolute = LateJunction.absolute('http://www.bbc.co.uk')

    absolute[{'href' => 'news/'}].
      should.equal 'http://www.bbc.co.uk/news/'
  end
end

describe 'LateJunction.cache_filename' do
  it 'should return a filename in CACHE_DIRECTORY' do
    File.split(LateJunction.cache_filename('foo')).first.
      should.equal LateJunction::CACHE_DIRECTORY
  end

  it 'should replace non-alphanumerics with dashes' do
    File.split(LateJunction.cache_filename('http://www.bbc.co.uk/')).last.
      should.equal 'http---www-bbc-co-uk-'
  end
end

describe 'LateJunction.html' do
  it 'should look in the cache first' do
  end

  it 'should return the parsed HTML' do
  end

  it 'should add the file contents to the cache' do
  end
end

describe 'LateJunction.presenter' do
  it 'should return the first presenter found' do
    LateJunction.presenter('Max Reinhardt Fiona Talkington').
      should.equal 'Max Reinhardt'

    LateJunction.presenter('Fiona Talkington Max Reinhardt').
      should.equal 'Fiona Talkington'
  end
end
