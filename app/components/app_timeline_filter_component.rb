# frozen_string_literal: true

class AppTimelineFilterComponent < ViewComponent::Base
  def initialize(
    url:,
    patient:,
    teams:,
    event_options:,
    timeline_fields:,
    additional_class_imports:,
    class_imports:,
    cohort_imports:,
    sessions:,
    reset_url:,
    show_pii:,
    pii_access_allowed:
  )
    @url = url
    @patient = patient
    @teams = teams.map(&:id)
    @event_options = event_options
    @timeline_fields = timeline_fields
    @additional_class_imports = additional_class_imports
    @class_imports = class_imports
    @cohort_imports = cohort_imports
    @sessions = sessions
    @reset_url = reset_url
    @show_pii = show_pii
    @pii_access_allowed = pii_access_allowed
  end

  attr_reader :url,
              :reset_url,
              :patient,
              :teams,
              :event_options,
              :timeline_fields,
              :additional_class_imports,
              :class_imports,
              :cohort_imports,
              :sessions,
              :show_pii,
              :pii_access_allowed
end
