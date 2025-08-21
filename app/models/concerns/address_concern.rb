# frozen_string_literal: true

module AddressConcern
  extend ActiveSupport::Concern

  included do
    normalizes :address_postcode,
               with: ->(value) do
                 value.nil? ? nil : UKPostcode.parse(value.to_s).to_s
               end

    belongs_to :local_authority_postcode,
               foreign_key: :address_postcode,
               primary_key: :value,
               class_name: "LocalAuthority::Postcode",
               optional: true

    has_one :local_authority_from_postcode,
            through: :local_authority_postcode,
            source: :local_authority
  end

  def address_parts
    [
      address_line_1,
      address_line_2,
      address_town,
      address_postcode
    ].compact_blank
  end

  def has_address?
    address_parts.present?
  end

  def address_changed?
    address_line_1_changed? || address_line_2_changed? ||
      address_town_changed? || address_postcode_changed?
  end
end
