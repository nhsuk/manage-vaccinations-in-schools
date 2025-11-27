# frozen_string_literal: true

module Confirmable
  extend ActiveSupport::Concern

  included do
    scope :confirmation_sent, -> { where.not(confirmation_sent_at: nil) }
    scope :confirmation_not_sent, -> { where(confirmation_sent_at: nil) }
  end

  def confirmation_sent? = confirmation_sent_at != nil

  def confirmation_sent!
    return if confirmation_sent?

    if new_record?
      update!(confirmation_sent_at: Time.current)
    else
      update_column(:confirmation_sent_at, Time.current)
    end
  end
end
