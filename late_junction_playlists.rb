require 'sinatra'
require 'sinatra/reloader'
require 'schema'

get '/' do
  @episodes = Episode.all(:order => [:date.desc])

  erb <<TEMPLATE
<html>
<title>Late Junction playlists</title>
<body>
<ol>
<% @episodes.each do |episode| %>
  <li>
    <a href="/<%= episode.id %>/"><%= episode.id %> - <%= episode.date %></a>:
    <%= episode.playlist_tracks.length %>
  </li>
<% end %>
</ol>
</body>
</html>
TEMPLATE
end

get '/:episode/' do
  @episode = Episode.get(params['episode'])

  erb <<TEMPLATE
<html>
<title><%= @episode.date %></title>
<body>
<h2>
  <a href="<%= @episode.uri %>"><%= @episode.id %> - <%= @episode.date %></a>
</h2>
<ol>
<% @episode.playlist_tracks.each do |playlist_track| %>
  <li>
    <code>
      <%= playlist_track.track.name %> -
      <%= playlist_track.artists.map {|a| a.name }.join(', ') %>
    </code>
  </li>
<% end %>
</ol>
</body>
</html>
TEMPLATE

end
