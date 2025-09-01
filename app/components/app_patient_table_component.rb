# frozen_string_literal: true

class AppPatientTableComponent < ViewComponent::Base
  def initialize(patients, current_user:, count:)
    @patients = patients
    @current_user = current_user
    @count = count
  end

  private

  attr_reader :patients, :current_user, :count

  def can_link_to?(record) = allowed_ids.include?(record.id)

  def allowed_ids
    @allowed_ids ||= PatientPolicy::Scope.new(current_user, Patient).resolve.ids
  end
end
