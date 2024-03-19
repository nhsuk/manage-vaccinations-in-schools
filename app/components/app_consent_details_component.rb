class AppConsentDetailsComponent < ViewComponent::Base
  def call
    props = { name: first_consent.name }
    unless first_consent.via_self_consent?
      props[:relationship] = first_consent.who_responded
      props[:contact] = {
        phone: first_consent.parent_phone,
        email: first_consent.parent_email
      }
    end
    props[:response] = @consents.map do |consent|
      { text: consent.summary_with_route, timestamp: consent.recorded_at }
    end
    if first_refused_consent.present?
      props[:refusal_reason] = {
        reason: first_refused_consent.human_enum_name(:reason_for_refusal),
        notes: first_refused_consent.reason_for_refusal_notes
      }
    end

    render AppConsentSummaryComponent.new(**props)
  end

  def initialize(consents:)
    super

    @consents = consents
  end

  private

  def first_consent
    @consents.first
  end

  def first_refused_consent
    @consents.find_all(&:response_refused?).first
  end
end
