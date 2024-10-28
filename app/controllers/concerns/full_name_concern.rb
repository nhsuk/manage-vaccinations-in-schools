# frozen_string_literal: true

module FullNameConcern
  extend ActiveSupport::Concern

  included { scope :order_by_name, -> { order(:given_name, :family_name) } }

  def full_name
    [given_name, family_name].join(" ")
  end

  def has_preferred_name?
    preferred_given_name.present? || preferred_family_name.present?
  end

  def preferred_full_name
    [
      preferred_given_name.presence || given_name,
      preferred_family_name.presence || family_name
    ].join(" ")
  end

  def preferred_full_name_changed?
    preferred_given_name_changed? || preferred_family_name_changed?
  end

  def initials
    [given_name[0], family_name[0]].join
  end
end
