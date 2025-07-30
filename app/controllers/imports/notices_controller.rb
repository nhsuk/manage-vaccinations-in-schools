# frozen_string_literal: true

class Imports::NoticesController < ApplicationController
  layout "full"

  def index
    authorize :notices

    @deceased_patients = policy_scope(Patient).deceased
    @invalidated_patients = policy_scope(Patient).invalidated
    @restricted_patients = policy_scope(Patient).restricted
    @gillick_no_notify_patients = policy_scope(Patient).gillick_no_notify
  end
end
