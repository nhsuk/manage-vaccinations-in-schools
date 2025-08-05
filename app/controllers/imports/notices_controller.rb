# frozen_string_literal: true

class Imports::NoticesController < ApplicationController
  layout "full"

  def index
    authorize :notices

    @deceased_patients = policy_scope(Patient).deceased
    @invalidated_patients = policy_scope(Patient).invalidated
    @restricted_patients = policy_scope(Patient).restricted
    @has_vaccination_records_dont_notify_parents_patients =
      policy_scope(Patient).has_vaccination_records_dont_notify_parents
  end
end
