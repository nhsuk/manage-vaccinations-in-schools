# frozen_string_literal: true

class TriageForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attr_accessor :patient, :session, :programme, :current_user

  attribute :add_patient_specific_direction, :boolean
  attribute :notes, :string
  attribute :status_and_vaccine_method, :string
  attribute :vaccine_methods, array: true, default: []

  validates :add_patient_specific_direction,
            inclusion: {
              in: [true, false]
            },
            if: :requires_add_patient_specific_direction?
  validates :status_and_vaccine_method,
            inclusion: {
              in: :status_and_vaccine_method_options
            }
  validates :notes, length: { maximum: 1000 }

  def triage=(triage)
    self.status_and_vaccine_method =
      if triage.ready_to_vaccinate?
        if consented_vaccine_methods.length > 1
          "safe_to_vaccinate_#{triage.vaccine_method}"
        else
          "safe_to_vaccinate"
        end
      elsif triage.needs_follow_up?
        "keep_in_triage"
      else
        triage.status
      end
  end

  def save
    save! if valid?
  end

  def save!
    ActiveRecord::Base.transaction do
      handle_patient_specific_direction
      Triage.create!(triage_attributes)
    end
  end

  def safe_to_vaccinate_options
    if programme.has_multiple_vaccine_methods?
      consented_vaccine_methods.map { |method| "safe_to_vaccinate_#{method}" }
    else
      ["safe_to_vaccinate"]
    end
  end

  def other_options
    %w[keep_in_triage delay_vaccination do_not_vaccinate]
  end

  def status_and_vaccine_method_options
    safe_to_vaccinate_options + other_options
  end

  def consented_to_injection? = consented_vaccine_methods.include?("injection")

  def consented_to_injection_only? = consented_vaccine_methods == ["injection"]

  def show_add_patient_specific_direction?(option)
    session.psd_enabled? && option == "safe_to_vaccinate_nasal" &&
      can_create_patient_specific_directions?
  end

  private

  delegate :academic_year, :team, to: :session

  def consented_vaccine_methods
    @consented_vaccine_methods ||=
      vaccine_methods.presence ||
        patient.consent_status(programme:, academic_year:).vaccine_methods
  end

  def triage_attributes
    {
      notes:,
      team:,
      patient:,
      performed_by: current_user,
      programme:,
      status:,
      vaccine_method:,
      academic_year:
    }
  end

  def status
    case status_and_vaccine_method
    when "safe_to_vaccinate", "safe_to_vaccinate_injection",
         "safe_to_vaccinate_nasal"
      "ready_to_vaccinate"
    when "keep_in_triage"
      "needs_follow_up"
    else
      status_and_vaccine_method
    end
  end

  def vaccine_method
    case status_and_vaccine_method
    when "safe_to_vaccinate"
      consented_vaccine_methods.first
    when "safe_to_vaccinate_injection"
      "injection"
    when "safe_to_vaccinate_nasal"
      "nasal"
    end
  end

  def requires_add_patient_specific_direction?
    show_add_patient_specific_direction?(status_and_vaccine_method)
  end

  def can_create_patient_specific_directions?
    PatientSpecificDirectionPolicy.new(
      current_user,
      PatientSpecificDirection
    ).create?
  end

  def handle_patient_specific_direction
    if add_patient_specific_direction
      create_patient_specific_direction!
    else
      invalidate_patient_specific_directions!
    end
  end

  def create_patient_specific_direction!
    vaccine_method = "nasal"

    # TODO: Handle programmes with multiple nasal vaccines.
    vaccine = programme.vaccines.find_by(method: vaccine_method)

    attributes = {
      academic_year:,
      delivery_site: "nose",
      invalidated_at: nil,
      patient:,
      programme:,
      team:,
      vaccine:,
      vaccine_method:
    }

    return if patient.patient_specific_directions.exists?(attributes)

    patient.patient_specific_directions.create!(
      created_by: current_user,
      **attributes
    )
  end

  def invalidate_patient_specific_directions!
    patient
      .patient_specific_directions
      .where(academic_year:, programme:, team:)
      .invalidate_all
  end
end
