# frozen_string_literal: true

# == Schema Information
#
# Table name: programmes
#
#  id            :bigint           not null, primary key
#  academic_year :integer
#  active        :boolean          default(FALSE), not null
#  end_date      :date
#  name          :string
#  start_date    :date
#  type          :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  team_id       :integer          not null
#
# Indexes
#
#  idx_on_name_type_academic_year_team_id_f5cd28cbec  (name,type,academic_year,team_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (team_id => teams.id)
#
class Programme < ApplicationRecord
  include Draftable
  include WizardStepConcern

  self.inheritance_column = nil

  audited

  belongs_to :team

  has_and_belongs_to_many :vaccines

  has_many :consents, dependent: :destroy
  has_many :dps_exports, dependent: :destroy
  has_many :immunisation_imports, dependent: :destroy
  has_many :sessions, dependent: :destroy
  has_many :triage, dependent: :destroy

  has_many :batches, through: :vaccines
  has_many :cohort_imports, through: :team
  has_many :patient_sessions, through: :sessions
  has_many :patients, through: :patient_sessions
  has_many :vaccination_records, through: :patient_sessions

  has_many :import_issues,
           -> do
             joins(:patient).where(
               "patients.pending_changes != '{}' OR vaccination_records.pending_changes != '{}'"
             ).distinct
             #  .strict_loading # TODO: Uncomment this
           end,
           through: :immunisation_imports,
           source: :vaccination_records

  enum :type, { flu: "flu", hpv: "hpv" }, validate: { allow_nil: true }

  normalizes :name, with: ->(name) { name&.strip }

  on_wizard_step :details do
    validates :name,
              presence: true,
              uniqueness: {
                scope: %i[type academic_year team_id],
                allow_nil: true
              }

    validates :type, presence: true

    validates :academic_year,
              comparison: {
                greater_than_or_equal_to: 2000,
                less_than_or_equal_to: Time.zone.today.year + 5
              }
  end

  on_wizard_step :dates do
    validates :start_date,
              comparison: {
                greater_than_or_equal_to: :first_possible_start_date,
                less_than: :end_date
              }

    validates :end_date,
              comparison: {
                greater_than: :start_date,
                less_than_or_equal_to: :last_possible_end_date
              }
  end

  on_wizard_step :vaccines do
    validates :vaccines, presence: true
  end

  on_wizard_step :confirm do
    validates :active, presence: true
  end

  validate :vaccines_match_type

  def wizard_steps
    [:details, :dates, (:vaccines if active), :confirm].compact
  end

  def draft?
    !active
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

  def first_possible_start_date
    Date.new(academic_year || 2000, 1, 1)
  end

  def last_possible_end_date
    Date.new((academic_year || 2000) + 1, 12, 31)
  end

  def vaccines_match_type
    vaccine_types = vaccines.map(&:type).uniq
    unless vaccine_types.empty? || vaccine_types == [type]
      errors.add(:vaccines, :match_type)
    end
  end
end
