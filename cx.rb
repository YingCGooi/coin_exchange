require 'sinatra'
require 'sinatra/reloader' if development?
require 'tilt/erubis'
require 'sinatra/content_for'
require 'chartkick'
require 'json'
require 'net/http'
require 'bcrypt'
require 'yaml'
require 'pry'

ROOT = File.expand_path('..', __FILE__)

HISTORICAL_BPI_API = 'https://api.coindesk.com/v1/bpi/historical/close.json'
CURRENT_BPI_API = 'https://api.coindesk.com/v1/bpi/currentprice.json'
CURRENT_PRICES_API = 'https://min-api.cryptocompare.com/data/' \
  'pricemulti?fsyms=BTC,ETH&tsyms=USD'

TIME_OUT_SECONDS = (ENV["RACK_ENV"] == 'test' ? 2 : 1500)

CURRENCY_NAMES = {
  btc: 'Bitcoin',
  eth: 'Ether',
  usd: 'US Dollars'
}

configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, :escape_html => true
end

helpers do
  def home_page?
    %w[/].include? env['REQUEST_PATH']
  end

  def user_signed_in?
    session[:signin] && !timed_out?
  end
end

before do
  @users_data = YAML.load_file(user_data_file_path)
  File.write('../session_log.yml', session.to_yaml)

  sign_out_if_idle
end

def parse_api(url)
  uri = URI(url)
  response = Net::HTTP.get(uri)
  JSON.parse(response)
end

def user_data_file_path
  if ENV["RACK_ENV"] == 'test'
    'test/users_data.yml'
  else
    'users_data.yml'
  end
end

def validation_messages(username, password, agreed = nil)
  {
    "Please enter a username." => username.empty?,
    "Username must not contain spaces." => username.include?(' '),
    "Username too long." => username.size > 30,
    "Username '#{username}' is unavailable." => @users_data.key?(username),
    "Password too short." => (1..3).cover?(password.size),
    "Password must contain a non-space character." => password.strip.empty?,
    "Please accept the user agreement." => agreed != 'true'
  }
end

def create_new_user_data(password)
  {
    password: BCrypt::Password.create(password).to_s,
    created: Time.now.to_s,
    new_user: true,
    balances: { btc: 0, eth: 0, usd: rand(4999..9999) },
    transactions: []
  }
end

def credentials_match?(username, password)
  return false if !@users_data.key?(username)

  stored_password = @users_data[username][:password]
  BCrypt::Password.new(stored_password) == password
end

def sign_in(username)
  session[:signin] = { username: username, time: Time.now }
end

def reset_idle_time
  session[:signin][:time] = Time.now
end

def sign_out
  session.delete(:signin)
end

def timed_out?
  session_idle_seconds = Time.now - session[:signin][:time]
  session_idle_seconds > TIME_OUT_SECONDS
end

def require_user_signed_in
  unless user_signed_in?
    session[:failure] ||= 'Please sign-in to continue.'
    redirect '/signin'
  end
  reset_idle_time
end

def sign_out_if_idle
  if session[:signin] && timed_out?
    sign_out
    session[:failure] = 'You have been logged out due to inactivity.'
  end
end

def usd_funded_message
  username = session[:signin][:username]
  user_data = @users_data[username]
  new_user = user_data[:new_user]
  usd_balance = user_data[:balances][:usd]

  if new_user
    user_data[:new_user] = false
    "Sign-up bonus! Your account was funded <b>+$#{usd_balance}</b>.<br />"
  end
end

not_found do
  erb :not_found
end

get '/' do
  redirect '/dashboard' if user_signed_in?

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

  errors = validation_messages(new_username, @password, @agreed)

  if errors.none? { |_, condition| condition }
    @users_data[new_username] = create_new_user_data(@password)
    File.write(user_data_file_path, @users_data.to_yaml)

    session[:success] = "You have created a new account '#{new_username}'.<br />Please sign-in to continue."
    sign_out
    redirect '/signin'
  else
    session[:failure] = errors.select { |_, condition| condition }
                              .keys
                              .join('<br />')
    status 422
    erb :signup
  end
end

get '/signin' do
  erb :signin
end

post '/user/signin' do
  @username = params[:username].strip
  @password = params[:password]

  errors = validation_messages(@username, @password, 'true')

  if credentials_match?(@username, @password)
    sign_in(@username)
    session[:success] = "You have successfully signed in as " \
    "'#{session[:signin][:username]}'.<br />" \
    "#{usd_funded_message}" \
    "<em>Timestamp: #{session[:signin][:time]}.</em>"
    redirect '/'
  else
    session[:failure] = 'Invalid credentials. Please try again.'
    status 422
    erb :signin
  end
end

get '/dashboard' do
  require_user_signed_in

  username = session[:signin][:username]

  @portfolio = @users_data[username][:balances]

  current_prices = parse_api(CURRENT_PRICES_API)

  @counter_values = {
    btc: current_prices['BTC']['USD'],
    eth: current_prices['ETH']['USD'],
    usd: 1
  }

  erb :dashboard
end

post '/user/signout' do
  sign_out
  redirect '/'
end

get '/buy' do
  require_user_signed_in

  erb :buy
end

get '/sell' do
  require_user_signed_in

  erb :sell
end

get '/settings' do
  require_user_signed_in

  erb :settings
end