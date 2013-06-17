desc 'Add stable sequence IDs to presenters, for assigning colours later'
task :add_seqs do
  require 'schema'

  DB = Database('rake.log')

  unless Presenter.columns.include?(:seq)
    DB.alter_table(Presenter.table_name) do
      add_column :seq, Integer
    end

    Presenter.set_dataset Presenter.table_name
  end

  Presenter.all.sort_by {|x| x.id}.each_with_index do |presenter, i|
    presenter.update(:seq => i)
  end
end
