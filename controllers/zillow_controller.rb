require 'httparty'
require 'mini_portile2'
require 'uri'
require 'json'
require 'nokogiri'
require 'erb'
require 'csv'
require 'fileutils'

class ZillowController
  include HTTParty
  format :xml

  def initialize(file)
    $CALLS_REACHED     = false
    @original_file = file
  end

  def create_result_file
    file = File.expand_path("../ResultsFiles/Results_#{Date.today.strftime('%Y_%m_%')}")
    headers = %w(client_property_id address city state zip lot_size house_size result)
    CSV.open(file, 'w+') { |csv| csv << headers }
  end

  def open_file(file)
    csv = CSV.read(file, headers: true)
    csv
  end

  def check_headers(file_headers)
    expected_headers = %w(property_id address city state zip)
    puts 'Checking headers to make sure that they include the following: '
    expected_headers.each { |header| puts header }
    expected_headers.each do |header|
      unless file_headers.include?(header)
        error_message("Header not found: #{header}. Please format the file correctly and try again")
        exit
      end
    end
  end

  def list_expected_headers
    %w(property_id address city state zip)
  end

  def missing_headers(file_headers)
    expected_headers = list_expected_headers
    actual_headers = file_headers
    missing_headers = expected_headers - actual_headers
    missing_headers
  end

  def create_address(row)
    zip     = row['zip'] ||= ''
    address = {
      property_id:    row['property_id'],
      address:      row['address'],
      city:         row['city'],
      state:        row['state'],
      citystatezip: "#{row[:city]}, #{row[:state]} #{zip}",
      zip:          zip,
      lot_size:     row['lot_size'],
      house_size:   row['house_size'],
      result:       row['result']
    }
    address
  end

  def search_for_property(options={})
    options = {
      'zws-id'      => "X1-ZWz1e1c7ixioej_4aijl",
      :address      => nil,
      :city         => nil,
      :state        => nil,
      :zip          => nil,
      :citystatezip => nil
    }.merge!(options)
    if options[:result].nil? and $CALLS_REACHED == false
      response          = self.class.get('http://www.zillow.com/webservice/GetDeepSearchResults.htm', query: options).body
      parsed_info       = parse_response(response)
      the_whole_package = options.merge(parsed_info) unless options.nil? || parsed_info.nil?
      return the_whole_package
    else
      return options
    end
  end

  def parse_response(search_results)
    address_info              = {}
    address_info[:lot_size]   = Nokogiri::XML(search_results).xpath("//lotSizeSqFt").first.text unless Nokogiri::XML(search_results).xpath("//lotSizeSqFt").first.nil?
    address_info[:house_size] = Nokogiri(search_results).xpath("//finishedSqFt").first.text unless Nokogiri::XML(search_results).xpath("//finishedSqFt").first.nil?
    address_info[:zillow_zip] = Nokogiri::XML(search_results).xpath("//zipcode").first.text unless Nokogiri::XML(search_results).xpath("//zipcode").first.nil?
    return if Nokogiri(search_results).xpath("//message").first.nil?
    if Nokogiri(search_results).xpath("//message").first.text =~ /maximum number of calls for today/
      $CALLS_REACHED = true
      error_message('The number of calls to Zillow for the day has been surpassed. Please try again tomorrow.')
    else
      address_info[:result] = Nokogiri(search_results).xpath("//message").first.text
    end
    address_info
  end

  def write_to_results_file(results_file, address_info)

    CSV.open(results_file, 'a') do |csv|
      csv << [
        address_info[:property_id],
        address_info[:address],
        address_info[:city],
        address_info[:state],
        address_info[:zip],
        address_info[:lot_size],
        address_info[:house_size],
        address_info[:result]
      ]
    end
  end

  def create_headers
    file = File.expand_path("../ResultsFiles/#{Date.today.strftime('%Y_%m_%d')}_results.csv", __FILE__)
    headers = %w(property_id address city state zip lot_size house_size result)
    error_message('Results file already exists.')
    CSV.open(file, 'w+') { |csv| csv << headers }
    file
  end

  def backup_file(file)
    file_name = File.basename(file)
    puts "Backing up file: #{file_name} to BackupFiles/#{file_name}"
    puts "File (#{file_name}) already exists in backup." if File.exists?("../BackupFiles/#{file_name}")
    FileUtils.cp(file, '../BackupFiles')
  end

  def copy_results_to_original(original_file, results_file)
    puts "Copying results to the original file: #{original_file}"
    FileUtils.cp("../ResultsFiles/#{results_file}", original_file)
  end


  def create_romance(file)
    original_file = open_file(file)

    results_file = create_headers

    original_file.each do |row|
      next if row[:result] ==
        address      = create_address(row)
      address_info = search_for_property(address)
      next if address_info.nil?
      write_to_results_file(results_file, address_info)
    end

  end

end