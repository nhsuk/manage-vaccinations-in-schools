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
#  index_school_moves_on_patient_id                            (patient_id)
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

  def confirm!
    ActiveRecord::Base.transaction do
      update_patient!
      update_sessions!
      destroy! if persisted?
    end
  end

  def ignore!
    destroy! if persisted?
  end

  private

  def update_patient!
    patient.update!(school:, home_educated:, cohort:)
  end

  def update_sessions!
    session = new_session

    patient.patient_sessions.find_each(&:destroy_if_safe!)

    # Patient is moving to a school not managed by an organisation.
    # All we can do here is remove them from the cohort.
    return if session.nil?

    PatientSession.find_or_create_by!(patient:, session:)
  end

  def cohort
    (school&.organisation || organisation)&.cohorts&.find_or_create_by!(
      birth_academic_year: patient.date_of_birth.academic_year
    )
  end

  def new_session
    if in_clinic?
      # If they've been booked in to a clinic we don't move them to a
      # school session as it's likely they're in a clinic for a reason.
      # TODO: Ask the user what they want to do here.

      (school&.organisation || organisation)&.generic_clinic_session
    elsif home_educated || school.nil?
      organisation.generic_clinic_session
    elsif school.organisation
      existing_session =
        school.organisation.sessions.upcoming.find_by(location: school)

      # There are no upcoming sessions available for their chosen school.
      # This can happen if the parent fills out the form late.
      existing_session || school.organisation.generic_clinic_session
    end
  end

  def in_clinic?
    patient.patient_sessions.joins(:location).merge(Location.clinic).exists?
  end
end
