require 'sinatra'
require_relative 'controllers/zillow_controller'

class App < Sinatra::Base
  configure :development do
    register Sinatra::Reloader
  end

  get '/' do
    erb :index
  end

  post '/romance' do
    file = params[:input_file][:tempfile].path
    zillow = ZillowController.new
    csv = zillow.open_file(file)
    @expected_headers = zillow.list_expected_headers
    @missing_headers = zillow.missing_headers(csv.headers)
    erb :compatibility
  end
end
