# frozen_string_literal: true

class VaccinateForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attr_accessor :patient_session, :current_user, :todays_batch

  attribute :administered, :boolean
  attribute :dose_sequence, :integer
  attribute :programme_id, :integer
  attribute :vaccine_id, :integer

  validates :administered, inclusion: { in: [true, false] }
  validates :dose_sequence, presence: true
  validates :programme_id, presence: true
  validates :vaccine_id, presence: true, if: :administered

  def save(draft_vaccination_record:)
    return nil if invalid?

    draft_vaccination_record.reset!

    draft_vaccination_record.dose_sequence = dose_sequence
    draft_vaccination_record.outcome = "administered" if administered
    draft_vaccination_record.patient_session = patient_session
    draft_vaccination_record.performed_at = Time.current
    draft_vaccination_record.performed_by_user = current_user
    draft_vaccination_record.programme_id = programme_id
    draft_vaccination_record.vaccine_id = vaccine_id
    draft_vaccination_record.batch_id = todays_batch&.id

    draft_vaccination_record.save # rubocop:disable Rails/SaveBang
  end
end
