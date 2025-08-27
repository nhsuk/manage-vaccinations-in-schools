# frozen_string_literal: true

# == Schema Information
#
# Table name: patient_consent_statuses
#
#  id              :bigint           not null, primary key
#  academic_year   :integer          not null
#  status          :integer          default("no_response"), not null
#  vaccine_methods :integer          default([]), not null, is an Array
#  patient_id      :bigint           not null
#  programme_id    :bigint           not null
#
# Indexes
#
#  idx_on_patient_id_programme_id_academic_year_1d3170e398  (patient_id,programme_id,academic_year) UNIQUE
#  index_patient_consent_statuses_on_status                 (status)
#
# Foreign Keys
#
#  fk_rails_...  (patient_id => patients.id) ON DELETE => cascade
#  fk_rails_...  (programme_id => programmes.id)
#
class Patient::ConsentStatus < ApplicationRecord
  include HasVaccineMethods

  belongs_to :patient
  belongs_to :programme

  has_many :consents,
           -> { not_invalidated.response_provided.includes(:parent, :patient) },
           through: :patient

  has_many :vaccination_records,
           -> { kept.order(performed_at: :desc) },
           through: :patient

  scope :has_vaccine_method,
        ->(vaccine_method) do
          where("vaccine_methods[1] = ?", vaccine_methods.fetch(vaccine_method))
        end

  enum :status,
       { no_response: 0, given: 1, refused: 2, conflicts: 3, not_required: 4 },
       default: :no_response,
       validate: true

  validates :vaccine_methods, presence: true, if: :given?

  def assign_status
    self.status = generator.status
    self.vaccine_methods = generator.vaccine_methods
  end

  def vaccine_method_nasal? = vaccine_methods.include?("nasal")

  def create_or_update_reportable_consent_event
    event =
      ReportingAPI::ConsentEvent.find_or_initialize_by(
        source_id: self.id,
        source_type: self.class.name
      )

    consent = self.consents.where(programme_id: self.programme_id, academic_year: self.academic_year).includes(:parent, :team).last
    
    event.event_timestamp = consent&.submitted_at || Time.current
    event.event_type = self.status

    event.copy_attributes_from_references(
      patient: self.patient,
      patient_school: self.patient&.school,
      # Need to wait for PR 4345 to get merged into next before we can do this:
      # patient_local_authority: self.patient&.local_authority_from_postcode,
      parent: consent&.parent,
      parent_relationship: self.patient&.parent_relationships.find_by(parent_id: consent&.parent_id),
      consent: consent,
      consent_status: self,
      programme: self.programme,
      team: consent&.team,
      organisation: consent&.team&.organisation
    )

    event.save!
    event
  end

  private

  def generator
    @generator ||=
      StatusGenerator::Consent.new(
        programme:,
        academic_year:,
        patient:,
        consents:,
        vaccination_records:
      )
  end
end
