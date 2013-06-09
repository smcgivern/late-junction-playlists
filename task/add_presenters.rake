desc 'Add presenters from the whole episode text, where a presenter is missing'
task :add_presenters do
  require 'schema'
  require 'lib/late_junction'
  DB = Database('rake.log')

  Episode.
    where(:presenter => Presenter.where(Sequel.|({:name => nil},
                                                 {:name => ''}))).
    all.each do |episode|

    episode_page = LateJunction.html(episode.uri)
    look_in = episode_page.at('#pips-content') || episode_page.at('#synopsis')
    meta_text = episode_page.at('meta[@name="description"]')['content']
    episode_text = LateJunction.html_to_text(look_in)

    (presenter_name = LateJunction.presenter(episode_text)).empty? &&
      (presenter_name = LateJunction.presenter(meta_text))

    if presenter_name.empty?
      puts "Can't find presenter for episode from #{episode.date}"

      episode.update(:presenter => Presenter[:name => ''])
    else
      puts "Adding #{presenter_name} to episode from #{episode.date}"

      presenter = Presenter.find_or_create(:name => presenter_name)

      episode.update(:presenter => presenter)
    end
  end
end
