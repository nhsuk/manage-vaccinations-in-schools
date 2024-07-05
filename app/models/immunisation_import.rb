# frozen_string_literal: true

require "csv"

# == Schema Information
#
# Table name: immunisation_imports
#
#  id         :bigint           not null, primary key
#  csv        :text             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_immunisation_imports_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class ImmunisationImport < ApplicationRecord
  belongs_to :user

  validates :csv, presence: true

  def csv=(value)
    super(value.respond_to?(:read) ? value.read : value)
  end

  def process!(patient_session:)
    data = CSV.parse(csv, headers: true, skip_blanks: true)
    data.each do |row|
      record = Row.new(row).to_vaccination_record
      record.user = user
      record.patient_session = patient_session
      record.save!
    end
  end

  class Row
    def initialize(row)
      @row = row
    end

    def to_vaccination_record
      VaccinationRecord.new(
        administered: administered?,
        delivery_site:,
        delivery_method:,
        recorded_at: Time.zone.now
      )
    end

    def delivery_site
      {
        "left thigh" => :left_thigh,
        "right thigh" => :right_thigh,
        "left upper arm" => :left_arm_upper_position,
        "right upper arm" => :right_arm_upper_position,
        "left buttock" => :left_buttock,
        "right buttock" => :right_buttock,
        "nasal" => :nose
      }[
        @row["ANATOMICAL_SITE"]&.downcase
      ]
    end

    def delivery_method
      if @row["ANATOMICAL_SITE"]&.downcase == "nasal"
        :nasal_spray
      else
        :intramuscular
      end
    end

    def administered?
      @row["VACCINATED"].downcase == "yes"
    end
  end
end
