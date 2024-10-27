# frozen_string_literal: true

module Sendable
  extend ActiveSupport::Concern

  included do
    belongs_to :sent_by,
               class_name: "User",
               foreign_key: :sent_by_user_id,
               optional: true
  end
end
