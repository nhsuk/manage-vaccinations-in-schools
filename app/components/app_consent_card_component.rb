# frozen_string_literal: true

class AppConsentCardComponent < ViewComponent::Base
  def initialize(consent:)
    super

    @consent = consent
  end

  def heading
    by =
      {
        given: "Consent given by",
        refused: "Refusal confirmed by",
        not_provided: "Contacted"
      }[
        @consent.response.to_sym
      ]
    heading = "#{by} #{@consent.name}"
    heading += " (#{@consent.who_responded})" unless @consent.via_self_consent?
    heading
  end

  def call
    # BUG: this code was originally written with the assumption that it is called
    # when the user is contacting a refusing parent (that assumption is baked into the microcopy)
    # However, this code is also invoked when a user is recording the first verbal consent,
    # and in that case, it doesn't quite display the right thing:
    #
    #   Consent updated to given...
    #
    # (it's not actually being updated as there wasn't consent there before)
    # The code really needs awareness of whether there was a previous consent or not, and
    # if there was one, what the response was. i.e. the previous_response needs to be dynamic.

    render AppCardComponent.new(heading:) do
      render AppConsentSummaryComponent.new(
               name: @consent.parent_name,
               relationship: @consent.who_responded,
               contact: {
                 phone: @consent.parent_phone,
                 email: @consent.parent_email
               },
               response: {
                 text:
                   @consent.summary_with_route(previous_response: "refused"),
                 timestamp: @consent.recorded_at,
                 recorded_by: @consent.recorded_by
               },
               refusal_reason: {
                 reason: @consent.human_enum_name(:reason_for_refusal),
                 notes: @consent.reason_for_refusal_notes
               }
             )
    end
  end
end
