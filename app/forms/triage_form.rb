# frozen_string_literal: true

class TriageForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attr_accessor :patient_session, :programme, :current_user

  attribute :status_and_vaccine_method, :string
  attribute :notes, :string
  attribute :vaccine_methods, array: true, default: []

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
    Triage.create!(triage_attributes) if valid?
  end

  def save!
    Triage.create!(triage_attributes)
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

  private

  delegate :team, :patient, :session, to: :patient_session
  delegate :academic_year, to: :session

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
      academic_year: session.academic_year
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
end
