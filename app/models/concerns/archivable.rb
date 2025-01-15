# frozen_string_literal: true

module Archivable
  extend ActiveSupport::Concern

  included do
    scope :archived, -> { where.not(archived_at: nil) }
    scope :not_archived, -> { where(archived_at: nil) }
  end

  def archived?
    archived_at != nil
  end

  def archive!
    update!(archived_at: Time.current) unless archived?
  end
end
