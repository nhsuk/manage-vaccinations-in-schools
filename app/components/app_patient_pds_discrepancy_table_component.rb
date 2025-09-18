# frozen_string_literal: true

class AppPatientPDSDiscrepancyTableComponent < ViewComponent::Base
  def initialize(discrepancies:, current_user:)
    @discrepancies = discrepancies
    @current_user = current_user
  end

  private

  attr_reader :discrepancies, :current_user

  delegate :format_nhs_number, :govuk_table, to: :helpers

  def can_link_to?(record) = allowed_ids.include?(record.id)

  def allowed_ids
    @allowed_ids ||= PatientPolicy::Scope.new(current_user, Patient).resolve.ids
  end
end
