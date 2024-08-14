# frozen_string_literal: true

# == Schema Information
#
# Table name: campaigns
#
#  id            :bigint           not null, primary key
#  academic_year :integer          not null
#  end_date      :date
#  name          :string           not null
#  start_date    :date
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  team_id       :integer
#
# Foreign Keys
#
#  fk_rails_...  (team_id => teams.id)
#
class Campaign < ApplicationRecord
  audited

  belongs_to :team
  has_and_belongs_to_many :vaccines
  has_many :batches, through: :vaccines
  has_many :consents, dependent: :destroy
  has_many :immunisation_imports, dependent: :destroy
  has_many :patient_sessions, through: :sessions
  has_many :sessions, dependent: :destroy
  has_many :triage, dependent: :destroy
  has_many :vaccination_records, through: :patient_sessions
  has_many :dps_exports, dependent: :destroy

  validates :academic_year,
            presence: true,
            comparison: {
              greater_than_or_equal_to: 2000,
              less_than_or_equal_to: Time.zone.today.year + 5
            }
end
