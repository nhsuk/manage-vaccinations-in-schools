# frozen_string_literal: true

class AppVaccinationRecordTableComponent < ViewComponent::Base
  def initialize(vaccination_records, current_user:, pagy:)
    @vaccination_records = vaccination_records
    @current_user = current_user
    @pagy = pagy
  end

  private

  attr_reader :vaccination_records, :current_user, :pagy

  delegate :govuk_table, to: :helpers

  def can_link_to?(record) = allowed_ids.include?(record.id)

  def allowed_ids
    @allowed_ids ||=
      VaccinationRecordPolicy::Scope
        .new(@current_user, VaccinationRecord)
        .resolve
        .ids
  end
end
