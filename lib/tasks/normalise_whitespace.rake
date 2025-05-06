# frozen_string_literal: true

desc "Run \`normalise_whitespace\` on all relevant strings in the database"
task normalise_whitespace: :environment do
  Patient.find_each do |patient|
    patient_fields = %i[
      given_name
      family_name
      preferred_given_name
      preferred_family_name
      address_line_1
      address_line_2
      address_town
      registration
    ]

    patient_fields.each do |field|
      patient[field] = patient[field]&.normalise_whitespace
    end

    patient.save! if patient.changed?
  end

  Parent.find_each do |parent|
    parent.full_name = parent.full_name&.normalise_whitespace

    parent.save! if parent.changed?
  end
end
