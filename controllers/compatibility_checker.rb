require 'csv'

class CompatibilityChecker
  def initialize
  end

  def open_file(file)
    csv = CSV.read(file, headers: true)
    csv
  end

  def missing_headers(file_headers)
    expected_headers = %w[property_id address city state zip]
    actual_headers = file_headers
    missing_headers = expected_headers - actual_headers
    missing_headers
  end

  def check_zip_code(csv_file)
    zip_column = CSV.table(csv_file)[:zip]
    zip_column.each do |cell|
      return false unless cell.to_s.length == 5
    end
  end
end

comp = CompatibilityChecker.new
file_path = File.expand_path('../../test_files/file1.csv', __FILE__)
comp_file = comp.open_file(file_path)
missing_headers = comp.missing_headers(comp_file.headers)
puts missing_headers
zip = comp.check_zip_code(file_path)

comp = CompatibilityChecker.new
file_path = File.expand_path('../../test_files/file2.csv', __FILE__)
comp_file = comp.open_file(file_path)
missing_headers = comp.missing_headers(comp_file.headers)
puts missing_headers