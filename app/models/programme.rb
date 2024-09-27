# frozen_string_literal: true

# == Schema Information
#
# Table name: programmes
#
#  id         :bigint           not null, primary key
#  type       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  team_id    :integer          not null
#
# Indexes
#
#  index_programmes_on_team_id_and_type  (team_id,type) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (team_id => teams.id)
#
class Programme < ApplicationRecord
  self.inheritance_column = nil

  audited

  belongs_to :team

  has_and_belongs_to_many :sessions
  has_and_belongs_to_many :vaccines

  has_many :consent_forms
  has_many :consents
  has_many :dps_exports
  has_many :immunisation_imports
  has_many :triages
  has_many :vaccination_records
  has_many :teams

  has_many :batches, through: :vaccines
  has_many :patient_sessions, through: :sessions
  has_many :patients, through: :patient_sessions

  enum :type, { flu: "flu", hpv: "hpv" }, validate: true

  validate :vaccines_match_type

  def name
    human_enum_name(:type)
  end

  def vaccine_ids
    @vaccine_ids ||= vaccines.map(&:id)
  end

  def vaccine_ids=(ids)
    self.vaccines = Vaccine.where(id: ids)
  end

  YEAR_GROUPS_BY_TYPE = { "flu" => (0..11).to_a, "hpv" => (8..11).to_a }.freeze

  def year_groups
    YEAR_GROUPS_BY_TYPE.fetch(type)
  end

  private

  def vaccines_match_type
    errors.add(:vaccines, :blank) if vaccines.empty?

    vaccine_types = vaccines.map(&:type).uniq
    unless vaccine_types.empty? || vaccine_types == [type]
      errors.add(:vaccines, :match_type)
    end
  end
end
