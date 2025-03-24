# frozen_string_literal: true

# == Schema Information
#
# Table name: patient_vaccination_statuses
#
#  id           :bigint           not null, primary key
#  status       :integer          default("none_yet"), not null
#  patient_id   :bigint           not null
#  programme_id :bigint           not null
#
# Indexes
#
#  idx_on_patient_id_programme_id_e876faade2     (patient_id,programme_id) UNIQUE
#  index_patient_vaccination_statuses_on_status  (status)
#
# Foreign Keys
#
#  fk_rails_...  (patient_id => patients.id) ON DELETE => cascade
#  fk_rails_...  (programme_id => programmes.id)
#
class Patient::VaccinationStatus < ApplicationRecord
  belongs_to :patient
  belongs_to :programme

  has_many :consents,
           -> do
             not_invalidated.response_provided.eager_load(:parent, :patient)
           end,
           through: :patient

  has_many :triages, -> { not_invalidated }, through: :patient

  has_many :vaccination_records, -> { kept }, through: :patient

  enum :status,
       { none_yet: 0, vaccinated: 1, could_not_vaccinate: 2 },
       default: :none_yet,
       validate: true

  def assign_status
    self.status =
      if status_should_be_vaccinated?
        :vaccinated
      elsif status_should_be_could_not_vaccinate?
        :could_not_vaccinate
      else
        :none_yet
      end
  end

  private

  def status_should_be_vaccinated?
    VaccinatedCriteria.call(programme:, patient:, vaccination_records:)
  end

  def status_should_be_could_not_vaccinate?
    if ConsentGrouper.call(consents, programme_id:).any?(&:response_refused?)
      return true
    end

    triages.select { it.programme_id == programme_id }.last&.do_not_vaccinate?
  end
end
