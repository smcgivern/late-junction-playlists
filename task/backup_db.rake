desc 'Backup database file'
task :backup_db do
  ['', '-journal'].each do |s|
    if (file = "tmp/late_junction.db#{s}" and File.exist?(file))
      cp(file, file.gsub('.db', "#{Time.now.strftime('%Y%m%d-%H%M')}.db"))
    end
  end
end
