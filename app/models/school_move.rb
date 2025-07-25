# frozen_string_literal: true

# == Schema Information
#
# Table name: school_moves
#
#  id              :bigint           not null, primary key
#  home_educated   :boolean
#  source          :integer          not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organisation_id :bigint
#  patient_id      :bigint           not null
#  school_id       :bigint
#
# Indexes
#
#  idx_on_patient_id_home_educated_organisation_id_7c1b5f5066  (patient_id,home_educated,organisation_id) UNIQUE
#  index_school_moves_on_organisation_id                       (organisation_id)
#  index_school_moves_on_patient_id_and_school_id              (patient_id,school_id) UNIQUE
#  index_school_moves_on_school_id                             (school_id)
#
# Foreign Keys
#
#  fk_rails_...  (organisation_id => organisations.id)
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (school_id => locations.id)
#
class SchoolMove < ApplicationRecord
  audited associated_with: :patient

  include Schoolable

  belongs_to :patient

  belongs_to :organisation, optional: true

  enum :source,
       { parental_consent_form: 0, class_list_import: 1, cohort_import: 2 },
       prefix: true,
       validate: true

  validates :organisation,
            presence: {
              if: -> { school.nil? }
            },
            absence: {
              unless: -> { school.nil? }
            }

  def confirm!(user: nil)
    ActiveRecord::Base.transaction do
      update_patient!
      update_sessions!
      create_log_entry!(user:)
      SchoolMove.where(patient:).destroy_all if persisted?
    end
  end

  def ignore!
    destroy! if persisted?
  end

  private

  def academic_year = AcademicYear.pending

  def update_patient!
    patient.update!(home_educated:, school:)
  end

  def update_sessions!
    patient
      .patient_sessions
      .joins(:session)
      .where(sessions: { academic_year: })
      .destroy_all_if_safe

    sessions_to_add.find_each do |session|
      PatientSession.find_or_create_by!(patient:, session:)
    end

    StatusUpdater.call(patient:)
  end

  def sessions_to_add
    @sessions_to_add ||=
      begin
        scope =
          Session.includes(:location, :session_dates).where(academic_year:)

        if school
          scope.where(organisation: school.organisation, location: school).or(
            scope.where(
              organisation: school.organisation,
              locations: {
                type: "generic_clinic"
              }
            )
          )
        else
          scope.where(organisation:, locations: { type: "generic_clinic" })
        end
      end
  end

  def create_log_entry!(user:)
    SchoolMoveLogEntry.create!(home_educated:, patient:, school:, user:)
  end
end
