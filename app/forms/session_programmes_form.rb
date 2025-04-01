# frozen_string_literal: true

class SessionProgrammesForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attr_accessor :session

  attribute :programme_ids, array: true, default: []

  validates :programme_ids, presence: true
  validate :cannot_remove_programmes

  def save
    return false if invalid?

    session.programme_ids = programme_ids
    StatusUpdaterJob.perform_later(session:)

    true
  end

  def programme_ids=(values)
    super(values&.compact_blank&.map(&:to_i) || [])
  end

  private

  def cannot_remove_programmes
    if (session.programme_ids - programme_ids).present?
      errors.add(:programme_ids, :inclusion)
    end
  end
end
