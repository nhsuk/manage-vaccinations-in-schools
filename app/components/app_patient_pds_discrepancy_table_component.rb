# frozen_string_literal: true

class AppPatientPDSDiscrepancyTableComponent < ViewComponent::Base
  def initialize(discrepancies:, current_user:)
    super

    @discrepancies = discrepancies
    @current_user = current_user
  end

  private

  attr_reader :discrepancies, :current_user

  def can_link_to?(record)
    allowed_ids.include?(record.id)
  end

  def allowed_ids
    @allowed_ids ||= PatientPolicy::Scope.new(current_user, Patient).resolve.ids
  end
end
