# frozen_string_literal: true

class AppProgrammeStatusTagsComponent < ViewComponent::Base
  def initialize(programme_statuses, context:)
    super

    @programme_statuses = programme_statuses
    @context = context
  end

  def call
    safe_join(
      programme_statuses.map do |programme, status|
        programme_status_tag(programme, status)
      end
    )
  end

  private

  attr_reader :programme_statuses, :context

  def programme_status_tag(programme, status)
    programme_tag =
      tag.strong(
        programme.name,
        class: "nhsuk-tag app-tag--attached nhsuk-tag--white"
      )

    label = I18n.t(status, scope: [:patient_session, :status, context, :label])

    colour =
      I18n.t(status, scope: [:patient_session, :status, context, :colour])

    status_tag = tag.strong(label, class: "nhsuk-tag nhsuk-tag--#{colour}")

    tag.p(safe_join([programme_tag, status_tag]))
  end
end
