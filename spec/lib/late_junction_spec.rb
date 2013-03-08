require './spec/setup'
require './lib/late_junction'

require 'tmpdir'

def with_const(constant, new)
  previous = constant.dup
  constant[0..-1] = new

  yield

  constant[0..-1] = previous
end

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
  it 'should return the parsed HTML' do
    with_const(LateJunction::CACHE_DIRECTORY, 'spec/fixture') do
      LateJunction.html('pips').
        should.be.a lambda {|x| x.class == Nokogiri::HTML::Document}
    end
  end

  it 'should look in the cache first' do
    with_const(LateJunction::CACHE_DIRECTORY, 'spec/fixture') do
      LateJunction.html('pips').title.
          should.equal 'BBC - (none) - Late Junction - Archive'
    end
  end

  it 'should add the file contents to the cache' do
    dir = Dir.mktmpdir

    with_const(LateJunction::CACHE_DIRECTORY, dir) do
      LateJunction.html('spec/fixture/pips')

      File.exist?(File.join(dir, 'spec-fixture-pips')).
          should.equal true
    end

    FileUtils.remove_entry_secure(dir)
  end
end

describe 'LateJunction.html_to_text' do
  before do
    @tests = [
              '1<br>2', '3<br />4', '<p id="lede">5<br>6</p>',
              '<strong>No</strong>, he said, using <em>emphasis</em>.'
             ].map {|x| Nokogiri::HTML(x)}
  end

  it 'should replace paragraph and line-break tags with newlines' do
    @tests[0...-1].map {|x| LateJunction.html_to_text(x) }.
      should.equal ["\n1\n2\n", "\n3\n4\n", "\n5\n6\n"]
  end

  it 'should strip all tags' do
    LateJunction.html_to_text(@tests.last).strip.
      should.equal 'No, he said, using emphasis.'
  end
end

describe 'LateJunction.indices' do
  with_const(LateJunction::CACHE_DIRECTORY, 'spec/fixture') do
    it 'should find all episode indices on the page' do
      indices = LateJunction.indices(:legacy)

      indices.length.should.equal 1
      indices.first[-4..-1].should.equal '2004'
    end

    it 'should use the URI passed, if any' do
      LateJunction.indices(:legacy, 'http://www.bbc.co.uk/pips/').length.
        should.equal 5
    end
  end
end

describe 'LateJunction.episodes' do
  with_const(LateJunction::CACHE_DIRECTORY, 'spec/fixture') do
    it 'should find all episodes on the pages passed' do
      uris = [2004, 2005].map {|x| "http://www.bbc.co.uk/pips/#{x}/"}
      episodes = LateJunction.episodes(:legacy, uris)

      episodes.length.should.equal 286
      episodes.first[-5..-1].should.equal 'uoj0a'
    end

    it 'should pull indices if no uris passed' do
      LateJunction.episodes(:legacy).length.
        should.equal 14
    end
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

describe 'LateJunction.tracks' do
  before do
    with_const(LateJunction::CACHE_DIRECTORY, 'spec/fixture') do
      @pages = ['9eaog', '440gl'].
        map {|x| "http://www.bbc.co.uk/radio3/latejunction/pip/#{x}/"}.
        map {|x| LateJunction.html(x)}

      @playlists = @pages.
        map {|x| LateJunction.html_to_text(x.at('#play-list')) }.
        map {|x| LateJunction.tracks(x) }
    end
  end

  it 'should pull in as much track info as possible' do
    silent_night = {
      :time => '11:16',
      :title => 'Silent Night',
      :artists => ['Low'],
      :album => 'Christmas',
      :composer => 'Trad',
    }

    @playlists[0].length.should.equal 16
    @playlists[0][-5].should.equal silent_night
  end

  it 'should split tracks correctly' do
    @playlists[1][6][:title].should.equal 'El Noi de la Mare'
    @playlists[1][7][:title].should.equal 'El decembre congelat'
    @playlists[1][6][:artists].should.equal @playlists.last[7][:artists]
  end

  it 'should fix broken lines' do
    3.upto(9) do |i|
      @playlists[0][i][:artists].
        should.equal ['Susanna and the Magical Orchestra']
    end
  end
end
