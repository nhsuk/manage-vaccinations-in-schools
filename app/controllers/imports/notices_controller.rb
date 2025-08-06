# frozen_string_literal: true

class Imports::NoticesController < ApplicationController
  layout "full"

  def index
    authorize :notices

    @deceased_patients =
      policy_scope(Patient).deceased.includes(vaccination_records: :programme)
    @invalidated_patients =
      policy_scope(Patient).invalidated.includes(
        vaccination_records: :programme
      )
    @restricted_patients =
      policy_scope(Patient).restricted.includes(vaccination_records: :programme)
    @has_vaccination_records_dont_notify_parents_patients =
      policy_scope(
        Patient
      ).has_vaccination_records_dont_notify_parents.includes(
        vaccination_records: :programme
      )
  end
end
