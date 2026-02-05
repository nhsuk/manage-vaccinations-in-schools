# frozen_string_literal: true

module BelongsToPerformedByUser
  extend ActiveSupport::Concern

  included do
    belongs_to :performed_by,
               class_name: "User",
               foreign_key: :performed_by_user_id
  end
end
