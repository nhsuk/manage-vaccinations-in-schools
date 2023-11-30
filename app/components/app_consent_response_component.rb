class AppConsentResponseComponent < ViewComponent::Base
  def call
    response_contents =
      @consents.map do |consent|
        [
          tag.p(class: "nhsuk-u-margin-bottom-0") do
            "#{consent.human_enum_name(:response).capitalize} (online)"
          end,
          tag.p(class: date_and_time_p_classes) do
            date_and_time consent.created_at
          end
        ].join("\n").html_safe
      end

    response_contents.first if response_contents.size == 1

    tag.ul(class: "nhsuk-list") do
      response_contents.map { |content| tag.li(content) }.join("\n").html_safe
    end
  end

  def initialize(consents:)
    super

    @consents = consents
  end

  def date_and_time_p_classes
    %w[
      nhsuk-u-margin-bottom-2
      nhsuk-u-secondary-text-color
      nhsuk-u-font-size-16
      nhsuk-u-margin-bottom-0
    ].join(" ")
  end

  def date_and_time(date)
    date_text = date.to_fs(:nhsuk_date_short_month)
    at_time = date.strftime("%-l:%M%P")

    %(#{date_text} at <span class="nhsuk-u-margin-left-1">#{at_time}</span>).html_safe
  end
end
