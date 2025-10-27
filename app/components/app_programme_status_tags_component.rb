# frozen_string_literal: true

class AppProgrammeStatusTagsComponent < ViewComponent::Base
  def initialize(status_by_programme, context:)
    @status_by_programme = status_by_programme
    @context = context
  end

  def call
    safe_join(
      status_by_programme.map do |programme, hash|
        status = hash[:status]

        if programme.has_multiple_vaccine_methods? &&
             (vaccine_method = hash[:vaccine_method]).present?
          status = :"#{status}_#{vaccine_method}"
        end

        status = :"#{status}_without_gelatine" if hash[:without_gelatine]

        latest_session_status = hash[:latest_session_status] if status !=
          hash[:latest_session_status]

        status_tag(programme, status, latest_session_status)
      end
    )
  end

  private

  attr_reader :status_by_programme, :context

  def status_tag(programme, status, latest_session_status)
    programme_tag =
      tag.strong(
        programme.name,
        class: "nhsuk-tag app-tag--attached nhsuk-tag--white"
      )

    label = I18n.t(status, scope: [:status, context, :label])
    colour = I18n.t(status, scope: [:status, context, :colour])

    status_tag = tag.strong(label, class: "nhsuk-tag nhsuk-tag--#{colour}")

    latest_session_span =
      if latest_session_status && latest_session_status != "none_yet"
        tag.span(
          I18n.t(latest_session_status, scope: %i[status session label]),
          class: "nhsuk-u-secondary-text-colour"
        )
      end

    tag.p(safe_join([programme_tag, status_tag, latest_session_span].compact))
  end
end
