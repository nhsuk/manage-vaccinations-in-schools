# frozen_string_literal: true

class AppPatientCohortTableComponent < ViewComponent::Base
  def initialize(patient, current_user:)
    super

    @patient = patient
    @current_user = current_user
  end

  private

  attr_reader :patient, :current_user

  delegate :year_group, to: :patient

  def team
    @team ||=
      if current_user.selected_team.patients.include?(patient)
        current_user.selected_team
      end
  end
end
