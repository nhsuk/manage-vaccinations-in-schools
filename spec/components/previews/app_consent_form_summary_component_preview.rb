# frozen_string_literal: true

class AppConsentFormSummaryComponentPreview < ViewComponent::Preview
  def self_consent
    render AppConsentFormSummaryComponent.new(
             name: "Mary Smith",
             response: {
               text: "Consent given (self-consent)",
               timestamp: Time.zone.local(2024, 3, 2, 14, 23, 0)
             }
           )
  end

  def mum_refuses_consent_for_personal_reasons
    render AppConsentFormSummaryComponent.new(
             name: "Jane Smith",
             relationship: "mum",
             contact: {
               email: "js@example.com",
               phone: "079876554321"
             },
             response: {
               text: "Consent refused (online)",
               timestamp: Time.zone.local(2024, 3, 2, 14, 23, 0)
             },
             refusal_reason: {
               reason: "Personal choice"
             }
           )
  end

  def consent_refused_with_notes
    render AppConsentFormSummaryComponent.new(
             name: "Jane Smith",
             response: {
               text: "Consent refused (online)",
               timestamp: Time.zone.local(2024, 3, 2, 14, 23, 0)
             },
             refusal_reason: {
               reason: "Already had the vaccine",
               notes: "Had it at the GP"
             }
           )
  end

  def multiple_responses
    render AppConsentFormSummaryComponent.new(
             name: "Jane Smith",
             relationship: "mum",
             contact: {
               email: "js@example.com"
             },
             response: [
               {
                 text: "Consent refused (online)",
                 timestamp: Time.zone.local(2024, 3, 2, 14, 23, 0)
               },
               {
                 text: "Consent given (phone)",
                 timestamp: Time.zone.local(2024, 3, 5, 12, 48, 0),
                 recorded_by:
                   build(
                     :user,
                     family_name: "Joy",
                     given_name: "Nurse",
                     email: "nurse.joy@example.com"
                   )
               }
             ]
           )
  end
end
