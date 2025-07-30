# frozen_string_literal: true

class PatientMergeForm
  include PatientMergeFormConcern

  attr_accessor :current_user, :patient

  validates :nhs_number, nhs_number: true
end
