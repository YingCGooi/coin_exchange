require 'sinatra'
require 'sinatra/reloader' if development?
require 'chartkick'

get '/' do
  erb :index
end

__END__

@@ layout
<html>
<head>
  <script>
  var Chartkick = {"language": "es"};
  </script>
  <script src="http://www.google.com/jsapi"></script>
    <script src="/javascript/chartkick.js"></script>
</head>
<body>
  <%= yield %>
</body>
</html>

@@ index
<%= timeline [
  ["Washington", "1789-04-29", "1797-03-03"],
  ["Adams", "1797-03-03", "1801-03-03"],
  ["Jefferson", "1801-03-03", "1809-03-03"]
] %>