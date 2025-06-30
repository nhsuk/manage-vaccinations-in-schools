class ReportableConsentEvent < ApplicationRecord
  include DenormalizingConcern
  include ReportableEventMethods


end