# frozen_string_literal: true

# == Schema Information
#
# Table name: patient_session_session_statuses
#
#  id                 :bigint           not null, primary key
#  status             :integer          default("none_yet"), not null
#  patient_session_id :bigint           not null
#  programme_id       :bigint           not null
#
# Indexes
#
#  idx_on_patient_session_id_programme_id_8777f5ba39  (patient_session_id,programme_id) UNIQUE
#  index_patient_session_session_statuses_on_status   (status)
#
# Foreign Keys
#
#  fk_rails_...  (patient_session_id => patient_sessions.id) ON DELETE => cascade
#  fk_rails_...  (programme_id => programmes.id)
#
class PatientSession::SessionStatus < ApplicationRecord
  belongs_to :patient_session
  belongs_to :programme

  has_one :patient, through: :patient_session
  has_one :session, through: :patient_session

  has_many :consents,
           -> { not_invalidated.response_provided.includes(:parent, :patient) },
           through: :patient

  has_many :triages,
           -> { not_invalidated.order(created_at: :desc) },
           through: :patient

  has_many :vaccination_records,
           -> { kept.order(performed_at: :desc) },
           through: :patient

  has_one :session_attendance,
          -> { today },
          through: :patient_session,
          source: :session_attendances

  enum :status,
       {
         none_yet: 0,
         vaccinated: 1,
         already_had: 2,
         had_contraindications: 3,
         refused: 4,
         absent_from_session: 5,
         unwell: 6
       },
       default: :none_yet,
       validate: true

  def assign_status
    self.status =
      if status_should_be_vaccinated?
        :vaccinated
      elsif status_should_be_already_had?
        :already_had
      elsif status_should_be_had_contraindications?
        :had_contraindications
      elsif status_should_be_refused?
        :refused
      elsif status_should_be_absent_from_session?
        :absent_from_session
      elsif status_should_be_unwell?
        :unwell
      else
        :none_yet
      end
  end

  private

  delegate :academic_year, to: :session

  def status_should_be_vaccinated?
    vaccination_record&.administered?
  end

  def status_should_be_already_had?
    vaccination_record&.already_had?
  end

  def status_should_be_had_contraindications?
    vaccination_record&.contraindications? || triage&.do_not_vaccinate?
  end

  def status_should_be_refused?
    vaccination_record&.refused? ||
      (latest_consents.any? && latest_consents.all?(&:response_refused?))
  end

  def status_should_be_absent_from_session?
    vaccination_record&.absent_from_session? ||
      session_attendance&.attending == false
  end

  def status_should_be_unwell?
    vaccination_record&.not_well?
  end

  def latest_consents
    @latest_consents ||=
      ConsentGrouper.call(consents, programme_id:, academic_year:)
  end

  def triage
    @triage ||= TriageFinder.call(triages, programme_id:, academic_year:)
  end

  def vaccination_record
    @vaccination_record ||=
      vaccination_records.find do
        it.programme_id == programme.id &&
          it.session_id == patient_session.session_id
      end
  end
end
