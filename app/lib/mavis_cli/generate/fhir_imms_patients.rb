# frozen_string_literal: true

require_relative "../../mavis_cli"

module MavisCLI
  module Generate
    class FhirImmsPatients < Dry::CLI::Command
      desc "Generate FHIR IMMS test patients from CSV data"
      option :organisation,
             aliases: ["-o"],
             default: "R1L",
             desc: "ODS code of organisation to create patients for"

      def call(organisation:, **)
        MavisCLI.load_rails

        org = Organisation.find_by(ods_code: organisation)
        unless org
          puts "Error: Organisation with ODS code '#{organisation}' not found"
          return 1
        end

        FhirImmsPatientCreator.new(org).call
      end
    end
  end

  register "generate", aliases: ["g"] do |prefix|
    prefix.register "fhir-imms-patients", Generate::FhirImmsPatients
  end
end

class FhirImmsPatientCreator
  CSV_FILE_PATH = File.join(__dir__, "../data/fhir_imms_patients.csv")

  def initialize(organisation)
    @organisation = organisation
    @created_patients = []
    @errors = []
    @skipped_patients = []
    @sessions_patients_count = Hash.new(0)
    ensure_organisation_has_user
    @sessions = find_sessions
  end

  def call
    puts "Starting FHIR IMMS patient creation from CSV data"
    puts "Organisation: #{@organisation.name} (#{@organisation.ods_code})"
    puts

    csv_data = read_csv_file

    progress_bar = MavisCLI.progress_bar(csv_data.size)

    csv_data.each do |row|
      create_patient_from_row(row)
      progress_bar.increment
    end

    print_summary
  end

  private

  def ensure_organisation_has_user
    return if @organisation.users.any?

    # Create a default user for the organisation
    user =
      User.create!(
        email: "test.user@#{@organisation.ods_code.downcase}.nhs.uk",
        given_name: "Test",
        family_name: "User",
        uid: SecureRandom.uuid
      )

    @organisation.users << user
  end

  def read_csv_file
    unless File.exist?(CSV_FILE_PATH)
      raise "CSV file not found: #{CSV_FILE_PATH}"
    end

    # Read the file and remove BOM if present
    content = File.read(CSV_FILE_PATH, encoding: "UTF-8")
    content = content.gsub(/\A\uFEFF/, "") # Remove BOM

    CSV.parse(content, headers: true, encoding: "UTF-8")
  rescue StandardError => e
    puts "Error reading CSV file: #{e.message}"
    raise
  end

  def create_patient_from_row(row)
    # Parse the CSV row data
    nhs_number = row["CHILD_NHS_NUMBER"]&.strip
    given_name = row["CHILD_FIRST_NAME"]&.strip&.titleize
    family_name = row["CHILD_LAST_NAME"]&.strip&.titleize
    preferred_given_name = row["CHILD_PREFERRED_FIRST_NAME"]&.strip&.titleize
    date_of_birth = parse_date(row["CHILD_DATE_OF_BIRTH"])
    gender = parse_gender(row["CHILD_GENDER"])

    # Address fields
    address_line_1 = row["CHILD_ADDRESS_LINE_1"]&.strip
    address_line_2 = row["CHILD_ADDRESS_LINE_2"]&.strip
    address_town = row["CHILD_TOWN"]&.strip
    address_postcode = row["CHILD_POSTCODE"]&.strip

    # School URN
    school_urn = row["CHILD_SCHOOL_URN"]&.strip

    # Skip if essential data is missing
    if given_name.blank? || family_name.blank? || date_of_birth.nil?
      @errors << "Skipping row - missing essential data: #{row.to_h}"
      return
    end

    # Skip if birth date is too old (before 1990 academic year)
    birth_academic_year = date_of_birth.academic_year
    if birth_academic_year < 1990
      @skipped_patients << "#{given_name} #{family_name} - birth year #{birth_academic_year} is before 1990"
      return
    end

    # Check if patient already exists
    existing_patient =
      Patient.find_by(nhs_number: nhs_number) if nhs_number.present?
    if existing_patient
      @skipped_patients << "#{given_name} #{family_name} - patient already exists with NHS number #{nhs_number}"
      return
    end

    # Find school by URN
    school = find_school_by_urn(school_urn) if school_urn.present?

    # Create the patient
    patient =
      Patient.create!(
        nhs_number: nhs_number.presence,
        given_name: given_name,
        family_name: family_name,
        preferred_given_name: preferred_given_name.presence,
        date_of_birth: date_of_birth,
        birth_academic_year: birth_academic_year,
        gender_code: gender,
        address_line_1: address_line_1.presence,
        address_line_2: address_line_2.presence,
        address_town: address_town.presence,
        address_postcode: address_postcode.presence,
        school: school,
        home_educated: nil # Always nil since we have a school
      )

    # Randomly select a session for this patient
    session = @sessions.sample

    # Associate the patient with the randomly selected session
    PatientSession.create!(patient: patient, session: session)

    # Track which session this patient was added to
    @sessions_patients_count[session.id] += 1

    @created_patients << patient
  rescue StandardError => e
    @errors << "Error creating patient from row #{row.to_h}: #{e.message}"
  end

  def parse_date(date_string)
    return nil if date_string.blank?

    # Handle YYYYMMDD format
    if date_string.match?(/^\d{8}$/)
      Date.strptime(date_string, "%Y%m%d")
    else
      Date.parse(date_string)
    end
  rescue StandardError
    nil
  end

  def parse_gender(gender_string)
    return "not_known" if gender_string.blank?

    case gender_string.downcase.strip
    when "male", "m"
      "male"
    when "female", "f"
      "female"
    when "not specified"
      "not_specified"
    else
      "not_known"
    end
  end

  def find_school_by_urn(urn)
    Location.find_by(urn: urn, type: "school")
  end

  def find_sessions
    # Find all existing sessions for the organisation
    sessions = Session.where(organisation_id: @organisation.id).to_a

    if sessions.empty?
      puts "No existing sessions found for organisation #{@organisation.name}. Please create at least one session first."
      raise "No existing sessions found"
    end

    puts "Found #{sessions.size} existing sessions for distribution"
    sessions
  end


  def print_summary
    puts "\n#{"=" * 50}"
    puts "FHIR IMMS PATIENTS GENERATION SUMMARY"
    puts "=" * 50
    puts "Patients created: #{@created_patients.size}"
    puts "Patients skipped: #{@skipped_patients.size}"
    puts "Errors encountered: #{@errors.size}"

    # Display distribution of patients across sessions
    puts "\nPatients distribution across sessions:"
    @sessions_patients_count.each do |session_id, count|
      puts "  - Session #{session_id}: #{count} patients"
    end

    if @skipped_patients.any?
      puts "\nSkipped patients:"
      @skipped_patients.each { |patient| puts "  - #{patient}" }
    end

    if @errors.any?
      puts "\nErrors:"
      @errors.each { |error| puts "  - #{error}" }
    end

    puts "\nPatients have been created successfully and distributed across sessions!"
  end
end
