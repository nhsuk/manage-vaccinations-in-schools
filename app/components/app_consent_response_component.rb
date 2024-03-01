class AppConsentResponseComponent < ViewComponent::Base
  def call
    response_contents =
      @consents.map do |consent|
        [
          tag.p(class: "nhsuk-body") do
            "#{response(consent:)} (#{route(consent:)})"
          end,
          tag.p(class: date_and_time_p_classes) do
            [
              recorded_by_link(consent:),
              date_and_time(consent.recorded_at)
            ].join("<br />").html_safe
          end
        ].join("\n").html_safe
      end

    return response_contents.first if response_contents.size == 1

    tag.ul(class: "nhsuk-list") do
      response_contents.map { |content| tag.li(content) }.join("\n").html_safe
    end
  end

  def initialize(consents:)
    super

    @consents = consents
  end

  private

  def date_and_time_p_classes
    %w[
      nhsuk-u-margin-bottom-2
      nhsuk-u-secondary-text-color
      nhsuk-u-font-size-16
      nhsuk-u-margin-bottom-0
    ].join(" ")
  end

  def date_and_time(date)
    %(#{date.to_fs(:nhsuk_date)} at #{date.to_fs(:time)}).html_safe
  end

  def response(consent:)
    consent.human_enum_name(:response).capitalize
  end

  def route(consent:)
    if consent.respond_to?(:route)
      consent.human_enum_name(:route).downcase
    else
      "online"
    end
  end

  def recorded_by_link(consent:)
    if consent.respond_to?(:via_phone?) && consent.via_phone?
      link_to(
        consent.recorded_by.full_name,
        "mailto:#{consent.recorded_by.email}"
      )
    else
      link_to(consent.parent_name, "mailto:#{consent.parent_email}")
    end
  end
end
