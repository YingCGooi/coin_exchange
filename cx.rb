require 'sinatra'
require 'sinatra/reloader' if development?
require 'tilt/erubis'
require 'chartkick'
require 'json'
require 'net/http'
require 'bcrypt'
require 'yaml'

root = File.expand_path('..', __FILE__)

HISTORICAL_BPI_API = 'https://api.coindesk.com/v1/bpi/historical/close.json'
CURRENT_BPI_API = 'https://api.coindesk.com/v1/bpi/currentprice.json'

configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, :escape_html => true
end

helpers do
  def home_page?
    %w[/].include? env['REQUEST_PATH']
  end

  def h(content)
    Rack::Utils.escape_html(content)
  end
end

before do
  @user_data = YAML.load_file(user_data_file_path)
end

def parse_api(url)
  uri = URI(url)
  response = Net::HTTP.get(uri)
  JSON.parse(response)
end

def user_data_file_path
  if ENV["RACK_ENV"] == "test"
    'test/user_data.yml'
  else
    'user_data.yml'
  end
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
  @username = params[:username]
  @password = params[:password]
  @agreed  = params[:agreed]
  new_username = @username.strip

  errors =
    {
      "Please enter a username." => new_username.empty?,
      "Username must not contain spaces." => new_username.include?(' '),
      "Username '#{new_username}' is unavailable." => @user_data.key?(new_username),
      "Password too short." => (1..3).cover?(@password.size),
      "Password must contain a non-space character." => @password.strip.empty?,
      "Please accept the user agreement." => @agreed.nil?
    }

  if errors.none? { |_, condition| condition }
    new_user_data = {
      password: BCrypt::Password.create(@password).to_s,
      created: Time.now.to_s,
      balances: { btc_bal: 0, eth_bal: 0, usd_bal: rand(4999..9999) },
      transactions: []
    }

    @user_data[new_username] = new_user_data
    File.write(user_data_file_path, @user_data.to_yaml)

    session[:success] = "You have created a new account '#{new_username}'.<br />Please sign-in to continue."

    redirect '/'
  else
    session[:failure] = 
      errors.select { |_, condition| condition }
            .keys
            .join('<br />')

    erb :signup
  end
end
