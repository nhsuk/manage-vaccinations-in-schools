# frozen_string_literal: true

require "net/http"
require "uri"
require "csv"

# Get the URNs from command line arguments
urns = ARGV

if urns.empty?
  puts "Usage: ruby script.rb URN1 URN2 ..."
  exit 1
end

results = []

# age_range_string is something like "3 to 11"
# number_of_pupils in the school as a string
# return an estimate of the number of pupils in the school for the year,
# assuming equal distribution across the age range
def year_estimate(age_range_string, number_of_pupils)
  # split the age range string into start and end ages
  start_age, end_age = age_range_string.split(" to ").map(&:to_i)

  raise "No end age found" if end_age.nil?

  # calculate the number of years in the age range
  number_of_years = end_age - start_age

  # calculate the number of pupils per year
  number_of_pupils.to_i / number_of_years
end

urns.each do |urn|
  puts "Fetching #{urn}"

  # Build the URL
  url =
    "https://get-information-schools.service.gov.uk/Establishments/Establishment/Details/#{urn}"

  # Fetch the webpage content
  uri = URI(url)
  response = Net::HTTP.get(uri)

  # Parse the response to find the school capacity and age range
  # Find all the summary list rows
  rows = response.scan(%r{<div class="govuk-summary-list__row">(.*?)</div>}m)

  found_pupils = false
  found_age_range = false
  number_of_pupils = ""
  age_range = ""

  rows.each do |row|
    # Extract dt and dd elements
    dt_match =
      row[0].match(
        %r{<dt class="govuk-summary-list__key">\s*(.*?)\s*(<a .*?</a>)?\s*</dt>}m
      )
    dd_match =
      row[0].match(%r{<dd class="govuk-summary-list__value">\s*(.*?)\s*</dd>}m)

    next unless dt_match && dd_match
    dt_text = dt_match[1].strip
    dd_text = dd_match[1].strip

    if dt_text.include?("Number of pupils")
      number_of_pupils = dd_text
      found_pupils = true
    elsif dt_text.include?("Age range")
      age_range = dd_text
      found_age_range = true
    end

    break if found_pupils && found_age_range
  end

  results << [urn, number_of_pupils, age_range]

  sleep 2
end

# Output CSV
CSV($stdout) do |csv|
  csv << %w[urn number_of_pupils year_estimate]
  results.each do |result|
    urn, number_of_pupils, age_range = result
    begin
      year_estimate = year_estimate(age_range, number_of_pupils)
      csv << [urn, number_of_pupils, year_estimate]
    rescue StandardError => e
      puts "Error: #{e.message} for URN #{urn}"
    end
  end
end
