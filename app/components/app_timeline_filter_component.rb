# frozen_string_literal: true

class AppTimelineFilterComponent < ViewComponent::Base
  def initialize(
    url:,
    patient:,
    team:,
    event_options:,
    timeline_fields:,
    additional_class_imports:,
    class_imports:,
    cohort_imports:,
    sessions:,
    reset_url:,
    show_pii:
  )
    super
    @url = url
    @patient = patient
    @team = team
    @event_options = event_options
    @timeline_fields = timeline_fields
    @additional_class_imports = additional_class_imports
    @class_imports = class_imports
    @cohort_imports = cohort_imports
    @sessions = sessions
    @reset_url = reset_url
    @show_pii = show_pii
  end

  attr_reader :url,
              :patient,
              :event_options,
              :timeline_fields,
              :additional_class_imports,
              :class_imports,
              :cohort_imports,
              :sessions,
              :reset_url,
              :show_pii
end
