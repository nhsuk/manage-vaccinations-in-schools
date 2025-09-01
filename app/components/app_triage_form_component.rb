# frozen_string_literal: true

class AppTriageFormComponent < ViewComponent::Base
  def initialize(
    triage_form,
    url:,
    method: :post,
    heading: true,
    continue: false
  )
    @triage_form = triage_form
    @url = url
    @method = method
    @heading = heading
    @continue = continue
  end

  private

  attr_reader :triage_form, :url, :method, :heading, :continue

  delegate :patient_session, :programme, to: :triage_form
  delegate :patient, :session, to: :patient_session

  def builder = GOVUKDesignSystemFormBuilder::FormBuilder

  def show_psd_options?(option)
    patient_session.session.psd_enabled? &&
      option == "safe_to_vaccinate_nasal" &&
      helpers.policy(PatientSpecificDirection).create?
  end

  def fieldset_options
    text = "Is it safe to vaccinate #{patient.given_name}?"
    hint =
      if programme.has_multiple_vaccine_methods?
        if triage_form.consented_to_injection_only?
          "The parent has consented to the injected vaccine only"
        elsif triage_form.consented_to_injection?
          "The parent has consented to the injected vaccine being offered if the nasal spray is not suitable"
        else
          "The parent has consented to the nasal spray only"
        end
      end

    if heading
      { legend: { text:, tag: :h2 }, hint: { text: hint } }
    else
      { legend: { text: }, hint: { text: hint } }
    end
  end
end
