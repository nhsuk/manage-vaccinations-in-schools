# frozen_string_literal: true

class AppSessionNeedsReviewWarningComponent < ViewComponent::Base
  def call
    render AppWarningCalloutComponent.new(heading: "Needs review") do
      tag.ul do
        safe_join(
          warning_counts.filter_map do |warning, _c|
            tag.li { make_row_from_warning(warning) }
          end
        )
      end
    end
  end

  def initialize(session:)
    super
    @session = session
  end

  def render?
    warning_counts.values.any?(&:positive?)
  end

  private

  def warning_href
    {
      children_without_nhs_number:
        session_patients_path(@session, missing_nhs_number: true)
    }
  end

  def warning_counts
    @warning_counts ||= {
      children_without_nhs_number:
        patient_sessions.merge(Patient.without_nhs_number).count
    }
  end

  def make_row_from_warning(warning)
    return if warning_counts[warning].zero?
    link_to(t(warning, count: warning_counts[warning]), warning_href[warning])
  end

  def patient_sessions
    @session
      .patient_sessions
      .joins(:patient, :session)
      .appear_in_programmes(@session.programmes)
  end
end
