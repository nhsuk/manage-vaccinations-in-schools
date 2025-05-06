# frozen_string_literal: true

class NormaliseWhitespace < ActiveRecord::Migration[8.0]
  def change
    reversible do |dir|
      dir.up do
        say_with_time "Normalizing whitespace in all Patient and Parent records" do
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
      end
    end
  end
end
