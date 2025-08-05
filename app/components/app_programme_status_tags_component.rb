# frozen_string_literal: true

class AppProgrammeStatusTagsComponent < ViewComponent::Base
  def initialize(programme_statuses, outcome:)
    super

    @programme_statuses = programme_statuses
    @outcome = outcome
  end

  def call
    safe_join(
      programme_statuses.map do |programme, hash|
        status = hash[:status]
        vaccine_methods =
          (hash[:vaccine_methods] if programme.has_multiple_vaccine_methods?)
        programme_status_tag(programme, status, vaccine_methods)
      end
    )
  end

  private

  attr_reader :programme_statuses, :outcome

  def programme_status_tag(programme, status, vaccine_methods)
    programme_tag =
      tag.strong(
        programme.name,
        class: "nhsuk-tag app-tag--attached nhsuk-tag--white"
      )

    label = I18n.t(status, scope: [:status, outcome, :label])
    colour = I18n.t(status, scope: [:status, outcome, :colour])

    status_tag = tag.strong(label, class: "nhsuk-tag nhsuk-tag--#{colour}")

    vaccine_methods_span =
      if vaccine_methods.present?
        tag.span(
          Vaccine.human_enum_name(:method, vaccine_methods.first),
          class: "nhsuk-u-secondary-text-color"
        )
      end

    tag.p(safe_join([programme_tag, status_tag, vaccine_methods_span]))
  end
end
