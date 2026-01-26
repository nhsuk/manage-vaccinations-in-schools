# frozen_string_literal: true

# == Schema Information
#
# Table name: triages
#
#  id                      :bigint           not null, primary key
#  academic_year           :integer          not null
#  delay_vaccination_until :date
#  disease_types           :enum             not null, is an Array
#  invalidated_at          :datetime
#  notes                   :text             default(""), not null
#  programme_type          :enum             not null
#  status                  :integer          not null
#  vaccine_method          :integer
#  without_gelatine        :boolean
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  patient_id              :bigint           not null
#  performed_by_user_id    :bigint
#  team_id                 :bigint
#
# Indexes
#
#  index_triages_on_academic_year         (academic_year)
#  index_triages_on_patient_id            (patient_id)
#  index_triages_on_performed_by_user_id  (performed_by_user_id)
#  index_triages_on_programme_type        (programme_type)
#  index_triages_on_team_id               (team_id)
#
# Foreign Keys
#
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (performed_by_user_id => users.id)
#  fk_rails_...  (team_id => teams.id)
#
class Triage < ApplicationRecord
  include BelongsToProgramme
  include Invalidatable
  include Notable

  audited associated_with: :patient

  belongs_to :patient
  belongs_to :team, optional: true
  belongs_to :performed_by,
             class_name: "User",
             foreign_key: :performed_by_user_id,
             optional: true

  enum :status,
       {
         safe_to_vaccinate: 0,
         do_not_vaccinate: 1,
         keep_in_triage: 2,
         delay_vaccination: 3,
         invite_to_clinic: 4
       },
       validate: true

  enum :vaccine_method,
       { injection: 0, nasal: 1 },
       validate: {
         if: :safe_to_vaccinate?
       }

  scope :for_session,
        ->(session) { where(programme_type: session.programme_types) }

  scope :safe_to_invalidate_automatically, -> { not_delay_vaccination }

  validates :delay_vaccination_until, absence: true, unless: :delay_vaccination?

  with_options if: :safe_to_vaccinate? do
    validates :vaccine_method, presence: true
    validates :without_gelatine, inclusion: [true, false]
  end

  def expired?
    delay_vaccination? && delay_vaccination_until.present? &&
      delay_vaccination_until <= Date.current
  end
end
