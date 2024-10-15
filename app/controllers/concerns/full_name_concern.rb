# frozen_string_literal: true

module FullNameConcern
  extend ActiveSupport::Concern

  included { scope :order_by_name, -> { order(:given_name, :family_name) } }

  def full_name
    "#{given_name} #{family_name}"
  end
end
