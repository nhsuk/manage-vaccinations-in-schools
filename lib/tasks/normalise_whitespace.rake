# frozen_string_literal: true

desc "Normalise the white space in a number of fields for patients and parents to ensure consistency."
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

    Patient.record_timestamps = false
    patient.save!
    Patient.record_timestamps = true
  end

  Parent.find_each do |parent|
    parent.full_name = parent.full_name&.normalise_whitespace

    Parent.record_timestamps = false
    parent.save!
    Parent.record_timestamps = true
  end
end
