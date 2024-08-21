# frozen_string_literal: true

module PerformedByConcern
  extend ActiveSupport::Concern

  included do
    belongs_to :performed_by,
               class_name: "User",
               optional: true,
               foreign_key: :performed_by_user_id
  end
end
