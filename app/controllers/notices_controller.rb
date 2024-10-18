# frozen_string_literal: true

class NoticesController < ApplicationController
  layout "full"

  def index
    @deceased_patients = policy_scope(Patient).deceased
    @invalidated_patients = policy_scope(Patient).invalidated
    @restricted_patients = policy_scope(Patient).restricted
  end
end
