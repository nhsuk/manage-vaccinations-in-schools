# frozen_string_literal: true

class AppVaccinationRecordTableComponent < ViewComponent::Base
  def initialize(vaccination_records, current_user:, count:)
    super

    @vaccination_records = vaccination_records
    @current_user = current_user
    @count = count
  end

  private

  attr_reader :vaccination_records, :current_user, :count

  def can_link_to?(record) = allowed_ids.include?(record.id)

  def allowed_ids
    @allowed_ids ||=
      VaccinationRecordPolicy::Scope
        .new(@current_user, VaccinationRecord.where(outcome: :administered))
        .resolve
        .ids
  end
end
