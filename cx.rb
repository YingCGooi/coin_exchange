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

def validation_messages(username, password, agreed = nil)
  {
    "Please enter a username." => username.empty?,
    "Username must not contain spaces." => username.include?(' '),
    "Username too long." => username.size > 30,
    "Username '#{username}' is unavailable." => @user_data.key?(username),
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
    balances: { btc_bal: 0, eth_bal: 0, usd_bal: rand(4999..9999) },
    transactions: []
  }
end

def credentials_match?(username, password)
  return false if !@user_data.key?(username)

  stored_password = @user_data[username][:password]
  BCrypt::Password.new(stored_password) == password
end

get '/' do
  # redirect '/dashboard' if signed_in?

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
    @user_data[new_username] = create_new_user_data(@password)

    File.write(user_data_file_path, @user_data.to_yaml)

    session[:success] = "You have created a new account '#{new_username}'.<br />Please sign-in to continue."

    redirect '/'
  else
    session[:failure] = 
      errors.select { |_, condition| condition }
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
    session[:username] = @username
    session[:success] = "You have successfully signed in as '#{session[:username]}'."
    redirect '/'
  else
    session[:failure] = 'Invalid credentials. Please try again.'
    status 422
    erb :signin
  end
end