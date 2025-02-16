# frozen_string_literal: true

class VaccinateForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attr_accessor :patient_session, :current_user, :todays_batch

  attribute :knows_vaccination, :boolean
  attribute :not_already_had, :boolean
  attribute :feeling_well, :boolean
  attribute :no_allergies, :boolean
  attribute :pre_screening_notes, :string

  attribute :administered, :boolean
  attribute :delivery_method, :string
  attribute :delivery_site, :string
  attribute :dose_sequence, :integer
  attribute :programme_id, :integer
  attribute :vaccine_id, :integer

  validates :knows_vaccination, inclusion: { in: [true, false] }
  validates :not_already_had, inclusion: { in: [true, false] }
  validates :feeling_well, inclusion: { in: [true, false] }
  validates :no_allergies, inclusion: { in: [true, false] }

  validate :valid_administered_values
  validates :dose_sequence, presence: true
  validates :programme_id, presence: true

  with_options if: :administered do
    validates :delivery_method, presence: true
    validates :delivery_site, presence: true
    validates :vaccine_id, presence: true
  end

  def save(draft_vaccination_record:)
    return nil if invalid?

    return false unless pre_screening.save

    draft_vaccination_record.reset!

    if administered
      draft_vaccination_record.outcome = "administered"

      if delivery_site != "other"
        draft_vaccination_record.delivery_method = delivery_method
        draft_vaccination_record.delivery_site = delivery_site
      end
    end

    draft_vaccination_record.batch_id = todays_batch&.id
    draft_vaccination_record.dose_sequence = dose_sequence
    draft_vaccination_record.patient_id = patient_session.patient_id
    draft_vaccination_record.performed_at = Time.current
    draft_vaccination_record.performed_by_user = current_user
    draft_vaccination_record.performed_ods_code = organisation.ods_code
    draft_vaccination_record.programme_id = programme_id
    draft_vaccination_record.session_id = patient_session.session_id
    draft_vaccination_record.vaccine_id = vaccine_id

    draft_vaccination_record.save # rubocop:disable Rails/SaveBang
  end

  private

  delegate :organisation, to: :patient_session

  def pre_screening
    @pre_screening ||=
      PreScreening.new(
        patient_session:,
        performed_by: current_user,
        knows_vaccination:,
        not_already_had:,
        feeling_well:,
        no_allergies:,
        notes: pre_screening_notes
      )
  end

  def valid_administered_values
    if administered.nil?
      errors.add(:administered, "Choose if they are ready to vaccinate")
    end

    vaccination_allowed =
      pre_screening.invalid? || pre_screening.allows_vaccination?

    if administered && !vaccination_allowed
      errors.add(:administered, "Patient should not be vaccinated")
    end
  end
end
