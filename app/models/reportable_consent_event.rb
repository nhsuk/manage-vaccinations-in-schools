class ReportableConsentEvent < ApplicationRecord
  include DenormalizingConcern
  include ReportableEventMethods

  enum :event_type, {
          consent_request_sent: "consent_request_sent",
          consent_given: "consent_given",
          consent_refused: "consent_refused",
          consent_not_provided: 'consent_not_provided',
      }, validate: true
end