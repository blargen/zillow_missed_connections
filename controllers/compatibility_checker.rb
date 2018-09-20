require 'csv'

class CompatibilityChecker
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
      return false unless cell.to_s =~ /^\d{5}$/
    end
  end
end
