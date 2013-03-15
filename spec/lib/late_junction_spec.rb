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
              '<div>1</div>2', '3<br />4', '<p id="lede">5<br>6</p>', '<h1>',
              '<strong>No</strong>, he said, using <em>emphasis</em>.'
             ].map {|x| Nokogiri::HTML(x)}
  end

  it 'should replace paragraph and line-break tags with newlines' do
    @tests[0...-1].map {|x| LateJunction.html_to_text(x) }.
      should.equal ["\n\n1\n2", "\n3\n4\n", "\n5\n6\n", "\n\n"]
  end

  it 'should strip all tags' do
    LateJunction.html_to_text(@tests.last).strip.
      should.equal 'No, he said, using emphasis.'
  end
end

describe 'LateJunction.inner_text' do
  it 'should return a block, based off root, which searches for selector' do
    text = LateJunction.inner_text(Nokogiri::HTML('<i>1</i><b>2</b>'))

    text['i'].should.equal '1'
    text['b'].should.equal '2'
  end

  it 'should return nil for missing elements' do
    LateJunction.inner_text(Nokogiri::HTML('<i>1</i>'))['b'].
      should.equal nil
  end
end

describe 'LateJunction.indices' do
  with_const(LateJunction::CACHE_DIRECTORY, 'spec/fixture') do
    it 'should find all episode indices on the page' do
      legacy = LateJunction.indices(:legacy)
      current = LateJunction.indices(:current)

      legacy.length.should.equal 1
      legacy.first[-4..-1].should.equal '2004'

      current.length.should.equal 1
      current.first[-7..-1].should.equal '2010/01'
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
      bbc = 'http://www.bbc.co.uk'
      legacy_uris = [2004, 2005].map {|x| "#{bbc}/pips/#{x}/"}
      current_uris = ["#{bbc}/programmes/b006tp52/broadcasts/2011/01"]
      legacy = LateJunction.episodes(:legacy, legacy_uris)
      current = LateJunction.episodes(:current, current_uris)

      legacy.length.should.equal 286
      legacy.first[-5..-1].should.equal 'uoj0a'
      current.length.should.equal 4
      current.first[-8..-1].should.equal 'b00xfhrt'
    end

    it 'should pull indices if no uris passed' do
      LateJunction.episodes(:legacy).length.should.equal 2
      LateJunction.episodes(:current).length.should.equal 13
    end
  end
end

describe 'LateJunction.playlists' do
  with_const(LateJunction::CACHE_DIRECTORY, 'spec/fixture') do
    before do
      @legacy = LateJunction.playlists(:legacy)
    end

    it "should return the episodes' playlists" do
      @legacy.length.should.equal 2
      @legacy[0][:tracks][0][:title].should.equal 'Proface! Welcome!'
      @legacy[1][:tracks][-5][:title].should.equal 'Silent Night'
      @legacy[1][:presenter].should.equal 'Fiona Talkington'
    end

    it 'should bail on metadata if the episode has no structured information' do
      [:date, :title, :description, :presenter].each do |key|
        @legacy[0][key].should.equal nil
      end

      @legacy[0][:uri].
        should.equal 'http://www.bbc.co.uk/radio3/latejunction/pip/440gl'
    end

    it 'should pull episodes by URI' do
      uris = ['http://www.bbc.co.uk/radio3/latejunction/pip/9eaog']

      LateJunction.playlists(:legacy, uris)[0].
        should.equal @legacy[1]
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
      @legacy = ['9eaog', '440gl'].
        map {|x| "http://www.bbc.co.uk/radio3/latejunction/pip/#{x}"}.
        map {|x| LateJunction.html(x)}.
        map {|x| LateJunction.html_to_text(x.at('#play-list')) }.
        map {|x| LateJunction.tracks(:legacy, x) }

      @current = ['b00q90qy', 'b00hr5ln'].
        map {|x| "http://www.bbc.co.uk/programmes/#{x}"}.
        map {|x| LateJunction.html(x)}.
        map {|x| x.at('#synopsis .copy')['content'] }.
        map {|x| LateJunction.tracks(:current, x) }
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

    la_llorona = {
      :time => '23:35',
      :title => 'La Llorona',
      :artists => ['Bairut'], # [sic]
      :album => 'March Of The Zapotec',
    }

    @legacy[0].length.should.equal 16
    @legacy[0][-5].should.equal silent_night
    @current[0].length.should.equal 27
    @current[1][5].should.equal la_llorona
  end

  it 'should split tracks correctly' do
    @legacy[1][6][:title].should.equal 'El Noi de la Mare'
    @legacy[1][7][:title].should.equal 'El decembre congelat'
    @legacy[1][6][:artists].should.equal @legacy.last[7][:artists]
  end

  it 'should fix broken lines' do
    3.upto(9) do |i|
      @legacy[0][i][:artists].
        should.equal ['Susanna and the Magical Orchestra']
    end
  end
end
