require 'sinatra'
require 'sinatra/reloader' if development?
require 'tilt/erubis'
require 'chartkick'
require 'json'
require 'net/http'
require 'bcrypt'

root = File.expand_path('..', __FILE__)
CURRENT_BPI_API = 'https://api.coindesk.com/v1/bpi/currentprice.json'
HISTORICAL_BPI_API = 'https://api.coindesk.com/v1/bpi/historical/close.json'

configure do
  enable :sessions
  set :session_secret, 'secret'
end

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
  @historical_bpi = parse_api(HISTORICAL_BPI_API)
  @min_price, @max_price = @historical_bpi['bpi'].values.minmax

  @current_bpi    = parse_api(CURRENT_BPI_API)
  @current_price  = @current_bpi['bpi']['USD']['rate']

  erb :charts
end

get '/signup' do
  erb :signup
end

post '/user/signup' do
  username = params[:username]
  password = params[:password]
  checked  = params[:checked]

  session[:success] = [username, password, checked]

  redirect '/'
end
