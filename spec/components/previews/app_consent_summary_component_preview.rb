# frozen_string_literal: true

class AppConsentSummaryComponentPreview < ViewComponent::Preview
  def self_consent
    render AppConsentSummaryComponent.new(
             name: "Mary Smith",
             response: {
               text: "Consent given (self-consent)",
               timestamp: Time.zone.local(2024, 3, 2, 14, 23, 0)
             }
           )
  end

  def mum_refuses_consent_for_personal_reasons
    render AppConsentSummaryComponent.new(
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
    render AppConsentSummaryComponent.new(
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
    render AppConsentSummaryComponent.new(
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
                     full_name: "Nurse Joy",
                     email: "nurse.joy@example.com"
                   )
               }
             ]
           )
  end
end
