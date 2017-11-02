require 'sinatra'
require 'sinatra/reloader' if development?
require 'tilt/erubis'
require 'chartkick'

root = File.expand_path('..', __FILE__)

helpers do
  def home_page?
    %w[/].include? env['REQUEST_PATH']
  end
end

get '/' do
  # redirect '/dashboard' if !signed_in?

  erb :index
end
