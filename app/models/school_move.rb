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
    SchoolMovesConfirmer.call([self], user:)
  end

  def ignore!
    destroy! if persisted?
  end

  def update_sessions!
    patient.patient_sessions.destroy_all_if_safe

    [school_session, generic_clinic_session].compact.each do |session|
      PatientSession.find_or_create_by!(patient:, session:)
    end

    StatusUpdater.call(patient:)
  end

  def create_log_entry!(user:)
    SchoolMoveLogEntry.create!(home_educated:, patient:, school:, user:)
  end

  private

  def school_session
    @school_session ||=
      if (org = school&.organisation)
        org
          .sessions
          .includes(:location, :session_dates)
          .for_current_academic_year
          .find_by(location: school)
      end
  end

  def generic_clinic_session
    @generic_clinic_session ||=
      (school&.organisation || organisation)&.generic_clinic_session
  end
end
