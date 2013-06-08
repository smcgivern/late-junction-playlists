desc 'Rotate logs in tmp/log'
task :rotate_logs do
  time = Time.now.strftime('%Y%m%d-%H%M')

  mkdir_p("tmp/log/#{time}")

  Dir['tmp/log/*.log'].each do |log|
    mv(log, log.gsub('/log/', "/log/#{time}/"))
  end
end
