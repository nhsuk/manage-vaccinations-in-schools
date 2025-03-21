# app/components/app_timeline_filter_component.rb
# frozen_string_literal: true

class AppTimelineFilterComponent < ViewComponent::Base
  def initialize(url:, 
                patient:, 
                event_options:, 
                timeline_fields:, 
                additional_class_imports:, 
                class_imports:, 
                cohort_imports:, 
                sessions:, 
                reset_url:)
    @url = url
    @patient = patient
    @event_options = event_options
    @timeline_fields = timeline_fields
    @additional_class_imports = additional_class_imports
    @class_imports = class_imports
    @cohort_imports = cohort_imports
    @sessions = sessions
    @reset_url = reset_url
  end

  attr_reader :url, :patient, :event_options, :timeline_fields,
              :additional_class_imports, :class_imports, :cohort_imports,
              :sessions, :reset_url
end
