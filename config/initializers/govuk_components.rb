# frozen_string_literal: true

Govuk::Components.configure do |config|
  config.brand = "nhsuk"
  config.brand_overrides = {
    "GovukComponent::NotificationBannerComponent" => "govuk",
    "GovukComponent::PanelComponent" => "govuk"
  }
end
