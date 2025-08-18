#frozen_string_literal: true

module MavisCLI
  module PDS
    class Search < Dry::CLI::Command
      desc "Search for a patient"

      option :given_name, desc: "Given name of the patient"
      option :family_name, desc: "Family name of the patient"
      option :gender, desc: "Gender of the patient"
      option :date_of_birth,
             desc: "Date of birth of the patient, example: eq2001-01-01"
      option :date_of_death,
             desc: "Date of death of the patient, example: eq2020-01-01"
      option :email, desc: "Email address of the patient"
      option :phone, desc: "Phone number of the patient"
      option :address_postcode, desc: "Postcode of the patient"
      option :general_practitioner, desc: "GP ODS code of the patient"
      option :max_results,
             desc: "Number of results to return",
             type: :integer,
             default: 10
      option :fuzzy_match,
             desc: "Whether to perform a fuzzy match",
             type: :boolean,
             default: false
      option :exact_match,
             desc: "Whether to perform an exact match",
             type: :boolean,
             default: false
      option :history,
             desc: "Whether to include history",
             type: :boolean,
             default: false

      def call(
        given_name: nil,
        family_name: nil,
        gender: nil,
        date_of_birth: nil,
        date_of_death: nil,
        email: nil,
        phone: nil,
        address_postcode: nil,
        general_practitioner: nil,
        max_results: 10,
        fuzzy_match: false,
        exact_match: false,
        history: false
      )
        MavisCLI.load_rails

        query = {
          "_fuzzy-match" => fuzzy_match,
          "_exact-match" => exact_match,
          "_history" => history,
          "_max-results" => max_results,
          "given" => given_name,
          "family" => family_name,
          "gender" => gender,
          "birthdate" => date_of_birth,
          "death-date" => date_of_death,
          "email" => email,
          "phone" => phone,
          "address-postalcode" => address_postcode,
          "general-practitioner" => general_practitioner
        }.compact

        response = NHS::PDS.search_patients(query)

        puts response.status unless response.status == 200
        puts response.env.url
        puts ""
        puts(response.headers.map { "#{_1}: #{_2}" })
        puts ""
        puts JSON.pretty_generate(response.body)
      end
    end
  end

  register "pds" do |prefix|
    prefix.register "search", PDS::Search
  end
end
