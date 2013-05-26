desc 'Load the admin interface'
task :admin do
  require 'rack'
  require 'admin'

  Sinatra::Application.run!
end
