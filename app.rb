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
    @file_path = params[:input_file][:tempfile].path
    @file_name = params[:input_file][:filename]
    @local_file_path = File.expand_path('public/files/source/source_file.csv', __dir__)
    FileUtils.copy(@file_path, @local_file_path)
    comp = CompatibilityChecker.new
    csv = comp.open_file(@local_file_path)
    @expected_headers = %w[property_id address city state zip]
    @missing_headers = comp.missing_headers(csv.headers)
    @zip_formatted_correctly = comp.check_zip_code(@local_file_path)
    erb :compatibility
  end

  get '/down_to_zillow' do
    erb :down_to_zillow
    file = File.expand_path('../public/files/source/source_file.csv', __FILE__)
    zillow = ZillowController.new
    results_file = zillow.create_romance(file)
    send_file(results_file)
  end
end
