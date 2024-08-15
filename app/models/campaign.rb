# frozen_string_literal: true

# == Schema Information
#
# Table name: campaigns
#
#  id            :bigint           not null, primary key
#  academic_year :integer          not null
#  active        :boolean          default(FALSE), not null
#  end_date      :date
#  name          :string           not null
#  start_date    :date
#  type          :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  team_id       :integer          not null
#
# Foreign Keys
#
#  fk_rails_...  (team_id => teams.id)
#
class Campaign < ApplicationRecord
  self.inheritance_column = nil

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

  enum :type, { flu: "flu", hpv: "hpv" }, validate: true

  scope :active, -> { where(active: true) }

  validates :name, presence: true

  validates :academic_year,
            comparison: {
              greater_than_or_equal_to: 2000,
              less_than_or_equal_to: Time.zone.today.year + 5
            },
            presence: true

  validates :start_date,
            comparison: {
              greater_than_or_equal_to: :first_possible_start_date,
              if: :academic_year,
              allow_nil: true
            },
            presence: {
              if: :active
            }

  validates :end_date,
            comparison: {
              greater_than_or_equal_to: :start_date,
              less_than_or_equal_to: :last_possible_end_date,
              if: -> { academic_year && start_date },
              allow_nil: true
            },
            presence: {
              if: :active
            }

  validate :vaccines_match_type

  private

  def first_possible_start_date
    Date.new(academic_year, 1, 1)
  end

  def last_possible_end_date
    Date.new(academic_year + 1, 12, 31)
  end

  def vaccines_match_type
    vaccine_types = vaccines.map(&:type).uniq
    unless vaccine_types.empty? || vaccine_types == [type]
      errors.add(:vaccines, "must match programme type")
    end
  end
end
