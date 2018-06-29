require 'sinatra'
require_relative 'controllers/zillow_controller'
require_relative 'controllers/compatibility_checker'

class App < Sinatra::Base
  configure :development do
    register Sinatra::Reloader
  end

  get '/' do
    erb :index
  end

  post '/compatibility' do
    @file = params[:input_file][:tempfile].path
    comp = CompatibilityChecker.new
    csv = comp.open_file(@file)
    @expected_headers = %w[property_id address city state zip]
    @missing_headers = comp.missing_headers(csv.headers)
    @zip_formatted_correctly = comp.check_zip_code(@file)
    erb :compatibility
  end

  post 'make_romance' do
    zillow = ZillowController.new
    zillow.create_romance(@file)
  end

  get '/down_to_zillow' do
    erb :down_to_zillow
  end
end
