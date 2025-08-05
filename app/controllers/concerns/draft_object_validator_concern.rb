# frozen_string_literal: true

module DraftObjectValidatorConcern
  extend ActiveSupport::Concern

  included do
    before_action :validate_patient_id_present, only: :show
  end

  # To be implemented by including controllers to specify which draft object to validate
  def draft_object
    raise NotImplementedError, "#{self.class} must implement #draft_object"
  end

  private

  def validate_patient_id_present
      if draft_object.patient_id.nil?
        render 'errors/no_draft_page_open', status: :unprocessable_entity
      end
  end
end