# frozen_string_literal: true

class VaccinateForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attr_accessor :patient_session, :current_user, :todays_batch

  attribute :administered, :boolean
  attribute :delivery_method, :string
  attribute :delivery_site, :string
  attribute :dose_sequence, :integer
  attribute :programme_id, :integer
  attribute :vaccine_id, :integer

  validates :administered, inclusion: { in: [true, false] }
  validates :delivery_method, presence: true, if: :administered
  validates :delivery_site, presence: true, if: :administered
  validates :dose_sequence, presence: true
  validates :programme_id, presence: true
  validates :vaccine_id, presence: true, if: :administered

  def save(draft_vaccination_record:)
    return nil if invalid?

    draft_vaccination_record.reset!

    if administered
      draft_vaccination_record.outcome = "administered"

      if delivery_site != "other"
        draft_vaccination_record.delivery_method = delivery_method
        draft_vaccination_record.delivery_site = delivery_site
      end
    end

    draft_vaccination_record.dose_sequence = dose_sequence
    draft_vaccination_record.patient_session = patient_session
    draft_vaccination_record.performed_at = Time.current
    draft_vaccination_record.performed_by_user = current_user
    draft_vaccination_record.programme_id = programme_id
    draft_vaccination_record.vaccine_id = vaccine_id
    draft_vaccination_record.batch_id = todays_batch&.id

    draft_vaccination_record.save # rubocop:disable Rails/SaveBang
  end
end
