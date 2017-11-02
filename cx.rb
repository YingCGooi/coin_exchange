require 'sinatra'
require 'sinatra/reloader' if development?
require 'tilt/erubis'
require 'chartkick'
require 'json'
require 'net/http'

root = File.expand_path('..', __FILE__)

helpers do
  def home_page?
    %w[/].include? env['REQUEST_PATH']
  end
end

def parse_api(url)
  uri = URI(url)
  response = Net::HTTP.get(uri)
  JSON.parse(response)
end

get '/' do
  # redirect '/dashboard' if !signed_in?

  erb :index
end

get '/charts' do
  @current_bpi = 
  parse_api('https://api.coindesk.com/v1/bpi/currentprice.json')
  @historical_bpi = 
    parse_api('https://api.coindesk.com/v1/bpi/historical/close.json')
  @min_price, @max_price = @historical_bpi['bpi'].values.minmax

  erb :charts
end

get '/signup' do
  erb :signup
end

post '/user/signup' do
  username = params[:username]
  password = params[:password]

end
