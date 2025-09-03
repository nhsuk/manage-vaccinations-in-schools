# frozen_string_literal: true

class AppTriageFormComponent < ViewComponent::Base
  def initialize(form, url:, method: :post, heading: true, continue: false)
    @form = form
    @url = url
    @method = method
    @heading = heading
    @continue = continue
  end

  private

  attr_reader :form, :url, :method, :heading, :continue

  delegate :policy, to: :helpers
  delegate :patient_session, :programme, to: :form
  delegate :patient, :session, to: :patient_session

  def builder = GOVUKDesignSystemFormBuilder::FormBuilder

  def show_psd_options?(option)
    patient_session.session.psd_enabled? &&
      option == "safe_to_vaccinate_nasal" &&
      policy(PatientSpecificDirection).create?
  end

  def fieldset_options
    text = "Is it safe to vaccinate #{patient.given_name}?"
    hint =
      if programme.has_multiple_vaccine_methods?
        if form.consented_to_injection_only?
          "The parent has consented to the injected vaccine only"
        elsif form.consented_to_injection?
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
