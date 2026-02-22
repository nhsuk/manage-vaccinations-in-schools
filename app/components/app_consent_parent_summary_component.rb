# frozen_string_literal: true

class AppConsentParentSummaryComponent < ViewComponent::Base
  def initialize(consentable, change_links: {})
    @consentable = consentable
    @patient = @consentable.patient if @consentable.is_a?(Consent)
    @change_links = change_links
  end

  def call
    govuk_summary_list do |summary_list|
      summary_list.with_row do |row|
        row.with_key { "Name" }

        if parent_full_name.present?
          row.with_value { parent_full_name }
          if (href = @change_links[:name])
            row.with_action(text: "Change", href:, visually_hidden_text: "name")
          end
        elsif (href = @change_links[:name])
          row.with_value { link_to("Add name", href) }
        else
          row.with_value { "Not provided" }
        end
      end

      summary_list.with_row do |row|
        row.with_key { "Relationship" }
        row.with_value { parent_relationship_label }
        if (href = @change_links[:relationship])
          row.with_action(
            text: "Change",
            href:,
            visually_hidden_text: "relationship"
          )
        end
      end

      unless @patient&.restricted?
        summary_list.with_row do |row|
          row.with_key { "Email address" }
          if parent_email.present?
            row.with_value do
              tag.p(parent_email, class: "nhsuk-body nhsuk-u-margin-0")
            end
            if (href = @change_links[:email])
              row.with_action(
                text: "Change",
                href:,
                visually_hidden_text: "email address"
              )
            end
          elsif (href = @change_links[:email])
            row.with_value { link_to("Add email address", href) }
          else
            row.with_value { "Not provided" }
          end
        end

        summary_list.with_row do |row|
          row.with_key { "Phone number" }
          if parent_phone.present?
            row.with_value do
              tag.p(parent_phone, class: "nhsuk-body nhsuk-u-margin-0")
            end
            if (href = @change_links[:phone])
              row.with_action(
                text: "Change",
                href:,
                visually_hidden_text: "phone number"
              )
            end
          elsif (href = @change_links[:phone])
            row.with_value { link_to("Add phone number", href) }
          else
            row.with_value { "Not provided" }
          end
        end

        summary_list.with_row do |row|
          row.with_key { "Get updates by text message" }
          row.with_value { parent_phone_receive_updates ? "Yes" : "No" }
          if (href = @change_links[:phone])
            row.with_action(
              text: "Change",
              href:,
              visually_hidden_text: "get updates by text message"
            )
          end
        end
      end
    end
  end

  private

  delegate :govuk_summary_list, :link_to, to: :helpers

  def parent_full_name
    @consentable.parent_full_name.presence || @consentable.parent&.full_name
  end

  def parent_email
    @consentable.parent_email.presence || @consentable.parent&.email
  end

  def parent_phone
    @consentable.parent_phone.presence || @consentable.parent&.phone
  end

  def parent_phone_receive_updates
    if @consentable.parent_phone_receive_updates.nil?
      @consentable.parent&.phone_receive_updates
    else
      @consentable.parent_phone_receive_updates
    end
  end

  def parent_relationship_label
    @consentable.who_responded
  end
end
