class AppConsentResponseComponent < ViewComponent::Base
  def initialize(consents:)
    super
    @consents = consents
  end

  def call
    if @consents.size == 1
      consent = @consents.first
      render AppTimestampedEntryComponent.new(
               text: summary_with_route(consent),
               timestamp: consent.recorded_at,
               recorded_by: staff_who_recorded(consent)
             )
    elsif @consents.size > 1
      tag.ul(class: "nhsuk-list nhsuk-list--bullet app-list--events") do
        safe_join(
          @consents.map do |entry|
            tag.li do
              render AppTimestampedEntryComponent.new(
                       text: summary_with_route(entry),
                       timestamp: entry.recorded_at,
                       recorded_by: staff_who_recorded(entry)
                     )
            end
          end
        )
      end
    end
  end

  private

  def summary_with_route(consent)
    route_string = consent.human_enum_name(:route).downcase.presence || "online"
    if consent.respond_to?(:response_not_provided?) &&
         consent.response_not_provided?
      "No response when contacted (#{route_string})"
    else
      "#{consent.human_enum_name(:response).capitalize} (#{route_string})"
    end
  end

  def staff_who_recorded(consent)
    consent.recorded_by if consent.respond_to?(:recorded_by)
  end
end
