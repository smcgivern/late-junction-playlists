require './spec/setup'
require './lib/late_junction'

require 'tmpdir'

def with_const(constant, new)
  previous = constant.dup
  constant[0..-1] = new

  yield

  constant[0..-1] = previous
end

describe 'LateJunction.add_time' do
  it 'should add two times as strings' do
    LateJunction.add_time('23:15', '00:00').should.equal '23:15'
  end

  it 'should wrap around hours' do
    LateJunction.add_time('22:15', '00:45').should.equal '23:00'
  end

  it 'should wrap around days' do
    LateJunction.add_time('23:15', '02:42').should.equal '01:57'
  end

  it 'should pad with zeroes' do
    LateJunction.add_time('23:15', '00:45').should.equal '00:00'
  end
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

describe 'LateJunction.uncache' do
  it 'should remove a URI from the cache' do
    dir = Dir.mktmpdir
    filename = File.join(dir, 'foo')
    file = open(filename, 'w')

    file.puts('Foo')
    file.flush

    with_const(LateJunction::CACHE_DIRECTORY, dir) do
      File.exist?(filename).should.equal true

      LateJunction.uncache('foo')

      File.exist?(filename).should.equal false
    end

    FileUtils.remove_entry_secure(dir)
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

  it 'should not look in the cache when force=true' do
    dir = Dir.mktmpdir
    filename = File.join(dir, 'spec-fixture-pips')
    file = open(filename, 'w')

    file.puts('<title>Cached copy</title>')
    file.flush

    with_const(LateJunction::CACHE_DIRECTORY, dir) do
      LateJunction.html('spec/fixture/pips', true).at('title').inner_text.
        should.equal 'BBC - (none) - Late Junction - Archive'

      File.stat(filename).size.
        should.satisfy {|x| x > 27}
    end

    FileUtils.remove_entry_secure(dir)
  end

  it 'should add the file contents to the cache' do
    dir = 'thisisatempdir'

    with_const(LateJunction::CACHE_DIRECTORY, dir) do
      LateJunction.html('spec/fixture/pips')

      File.exist?(File.join(dir, 'spec-fixture-pips')).
          should.equal true
    end

    FileUtils.remove_entry_secure(dir)
  end

  it "should create the cache directory if it doesn't exist" do
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

  it 'should return the empty string for non-HTML elements' do
    LateJunction.html_to_text(nil).
      should.equal ''
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
      LateJunction.episodes(:current).length.should.equal 2
    end
  end
end

describe 'LateJunction.playlists' do
  with_const(LateJunction::CACHE_DIRECTORY, 'spec/fixture') do
    before do
      @legacy = LateJunction.playlists(:legacy)
      @current = LateJunction.playlists(:current)
    end

    it "should return the episodes' playlists" do
      @legacy.length.should.equal 2
      @legacy[0][:tracks][0][:title].should.equal 'Proface! Welcome!'
      @legacy[1][:tracks][-5][:title].should.equal 'Silent Night'
      @legacy[1][:presenter].should.equal 'Fiona Talkington'

      @current.length.should.equal 2
      @current[1][:presenter].should.equal 'Max Reinhardt'
    end

    it 'should bail on metadata if the episode has no structured information' do
      [:date, :title, :description, :presenter].each do |key|
        @legacy[0][key].should.equal nil
      end

      @legacy[0][:uri].
        should.equal 'http://www.bbc.co.uk/radio3/latejunction/pip/440gl'
    end

    it "should bail on the playlist if there isn't one" do
      playlist = LateJunction.
        playlists(:legacy,
                  ['http://www.bbc.co.uk/radio3/latejunction/pip/0ej1z'])[0]

      playlist[:date].should.equal DateTime.civil(2006, 9, 29)
      playlist[:tracks].should.equal []
    end

    it 'should pull episodes by URI' do
      uris = ['http://www.bbc.co.uk/radio3/latejunction/pip/9eaog']

      LateJunction.playlists(:legacy, uris)[0].
        should.equal @legacy[1]
    end

    it 'should uncache any future episodes' do
      dir = Dir.mktmpdir
      uri = 'http://www.bbc.co.uk/programmes/b02x995v'
      filename = LateJunction.cache_filename(uri)

      with_const(LateJunction::CACHE_DIRECTORY, dir) do
        FileUtils.copy(filename, LateJunction.cache_filename(uri))

        File.exist?(LateJunction.cache_filename(uri)).should.equal true

        LateJunction.playlists(:current, [uri])

        File.exist?(LateJunction.cache_filename(uri)).should.equal false
      end

      FileUtils.remove_entry_secure(dir)
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
      @legacy = ['9eaog', '440gl', 'uk1se'].
        map {|x| "http://www.bbc.co.uk/radio3/latejunction/pip/#{x}"}.
        map {|x| LateJunction.html(x)}.
        map {|x| LateJunction.html_to_text(x.at('#play-list'), 'iso-8859-1') }.
        map {|x| LateJunction.tracks(:legacy, x) }

      @current = ['b00q90qy', 'b00q90wq'].
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

    casablanca = {
      :time => '00:56',
      :title => 'Casablanca',
      :artists => ['Lonely Drifter Karen'],
      :album => 'Grass Is Singing',
    }

    si_comme_la_lune = {
      :time => '23:28',
      :composer => 'Scriabine',
      :title => 'Si Comme La Lune',
      :artists => ['Laurence Equilbey, Accentus'],
      :album => 'Transcriptions 2',
    }

    @legacy[0].length.should.equal 16
    @legacy[0][-5].should.equal silent_night
    @current[0].length.should.equal 27
    @current[0][-1].should.equal casablanca
    @current[1][3].should.equal si_comme_la_lune
  end

  it 'should split tracks correctly' do
    @legacy[1][6][:title].should.equal 'El Noi de la Mare'
    @legacy[1][7][:title].should.equal 'El decembre congelat'
    @legacy[1][6][:artists].should.equal @legacy[1][7][:artists]
  end

  it "should ignore tracks which don't fit" do
    @legacy[2][1][:title].should.equal 'Bittertiles'
    @legacy[2][2][:title].should.equal 'Prophecies'
  end

  it 'should fix broken lines' do
    3.upto(9) do |i|
      @legacy[0][i][:artists].
        should.equal ['Susanna and the Magical Orchestra']
    end
  end
end

describe 'LateJunction.structured_tracks' do
  before do
    with_const(LateJunction::CACHE_DIRECTORY, 'spec/fixture') do
      static = ['b00xfg3p'].
        map {|x| "http://www.bbc.co.uk/programmes/#{x}"}.
        map {|x| LateJunction.html(x).at('#segments') }.
        map {|x| LateJunction.structured_tracks(x, '23:15') }

      dynamic = ['b04l37ph'].
        map {|x| "http://www.bbc.co.uk/programmes/#{x}/segments.inc"}.
        map {|x| LateJunction.html(x) }.
        map {|x| LateJunction.structured_tracks(x, '23:15') }

      @current = static + dynamic
    end
  end

  it 'should pull in as much track info as possible' do
    before_night = {
      :time => '00:48',
      :artists => ['Ensemble'],
      :title => 'Before Night',
      :album => 'Excerpts',
    }

    grapes_engraved = {
      :time => '23:50',
      :title => 'Grapes Engraved',
      :artists => ['Part Wild Horses Mane on Both Sides'],
      :album => 'Bataille De Battle'
    }

    @current[0].length.should.equal 22
    @current[0][-2].should.equal before_night

    @current[1].length.should.equal 17
    @current[1][6].should.equal grapes_engraved
  end
end
