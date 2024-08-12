# frozen_string_literal: true

# == Schema Information
#
# Table name: campaigns
#
#  id         :bigint           not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  team_id    :integer
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
end
