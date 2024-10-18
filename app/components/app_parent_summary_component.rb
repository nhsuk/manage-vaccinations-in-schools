# frozen_string_literal: true

class AppParentSummaryComponent < ViewComponent::Base
  def initialize(parent, relationship, change_links: {})
    super

    @parent = parent
    @relationship = relationship
    @change_links = change_links
  end

  def call
    govuk_summary_list do |summary_list|
      summary_list.with_row do |row|
        row.with_key { "Name" }
        row.with_value { @parent.full_name }
        if (href = @change_links[:name])
          row.with_action(text: "Change", href:, visually_hidden_text: "name")
        end
      end

      summary_list.with_row do |row|
        row.with_key { "Relationship" }
        row.with_value { @relationship.label }
        if (href = @change_links[:relationship])
          row.with_action(
            text: "Change",
            href:,
            visually_hidden_text: "relationship"
          )
        end
      end

      summary_list.with_row do |row|
        row.with_key { "Email address" }
        if @parent.email.present?
          row.with_value { @parent.email }
          if (href = @change_links[:email])
            row.with_action(
              text: "Change",
              href:,
              visually_hidden_text: "email address"
            )
          end
        elsif (href = @change_links[:email])
          row.with_value { govuk_link_to("Add email address", href) }
        else
          row.with_value { "Not provided" }
        end
      end

      summary_list.with_row do |row|
        row.with_key { "Phone number" }
        if @parent.phone.present?
          row.with_value { @parent.phone }
          if (href = @change_links[:phone])
            row.with_action(
              text: "Change",
              href:,
              visually_hidden_text: "phone number"
            )
          end
        elsif (href = @change_links[:phone])
          row.with_value { govuk_link_to("Add phone number", href) }
        else
          row.with_value { "Not provided" }
        end
      end

      if @parent.contact_method_type.present?
        summary_list.with_row do |row|
          row.with_key { "Phone contact method" }
          row.with_value { @parent.contact_method_description }
          if (href = @change_links[:phone])
            row.with_action(
              text: "Change",
              href:,
              visually_hidden_text: "phone contact method"
            )
          end
        end
      end
    end
  end
end
